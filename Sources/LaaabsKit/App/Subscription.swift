import Foundation
import StoreKit

/// a thin layer over storekit 2 for an app paid by a subscription: its products, what the person has
/// now, buying, restoring, and what went wrong said in plain words. nothing is counted or sent
/// anywhere: the store's own reports are the only numbers.
///
///     let subscription = Subscription(productIDs: ["com.laaabs.finaaance.monthly", "com.laaabs.finaaance.yearly"])
///     .task { await subscription.load() }
///     if subscription.isActive { ... }
@MainActor
@Observable
public final class Subscription {
    /// what the person has now
    public enum State: Equatable, Sendable {
        /// not asked the store yet
        case unknown
        /// no plan, or the last one has ended
        case none
        /// a plan that works: `renews` false once it is cancelled, `until` the end of the period paid
        case active(productID: String, renews: Bool, until: Date?)
        /// the renewal payment failed and the store is retrying; the app keeps working meanwhile
        case billingRetry(productID: String)
    }

    /// the products the store gives, cheapest first; the prices are the store's, never typed
    public private(set) var products: [Product] = []
    public private(set) var state: State = .unknown
    /// the last thing that went wrong, until the next action
    public private(set) var error: SubscriptionError?
    /// true while buying or restoring
    public private(set) var isWorking = false

    /// true when the app should open everything a plan opens
    public var isActive: Bool {
        switch state {
        case .active, .billingRetry: true
        case .unknown, .none: false
        }
    }

    private let productIDs: [String]
    nonisolated(unsafe) private var updates: Task<Void, Never>?

    public init(productIDs: [String]) {
        self.productIDs = productIDs
        // purchases made elsewhere (another device, a renewal, family sharing, a refund) arrive here
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case let .verified(transaction) = result { await transaction.finish() }
                await self?.refresh()
            }
        }
    }

    deinit { updates?.cancel() }

    /// asks the store for the products and what the person has. call it when the app starts.
    public func load() async {
        do {
            products = try await Product.products(for: productIDs).sorted { $0.price < $1.price }
            if products.isEmpty { error = .productsMissing }
        } catch {
            self.error = .storeUnavailable
        }
        await refresh()
    }

    /// buys a plan. true when it went through; a cancel is not an error.
    @discardableResult
    public func purchase(_ product: Product) async -> Bool {
        error = nil
        isWorking = true
        defer { isWorking = false }
        do {
            switch try await product.purchase() {
            case let .success(.verified(transaction)):
                await transaction.finish()
                await refresh()
                return true
            case .success(.unverified):
                error = .unverified
            case .pending:
                error = .pending
            case .userCancelled:
                break
            @unknown default:
                error = .purchaseFailed
            }
        } catch {
            self.error = .purchaseFailed
        }
        return false
    }

    /// asks the store again for what this apple account has bought, as the restore button does
    public func restore() async {
        error = nil
        isWorking = true
        defer { isWorking = false }
        do {
            try await AppStore.sync()
            await refresh()
            if !isActive { error = .nothingToRestore }
        } catch {
            self.error = .restoreFailed
        }
    }

    /// reads what the person has now: the store's current entitlements, else each plan's latest
    /// transaction (still paid for, not refunded, not replaced by an upgrade), then its renewal state
    public func refresh() async {
        var found: Transaction?
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result, productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil else { continue }
            found = transaction
        }
        if found == nil {
            for id in productIDs {
                guard case let .verified(transaction)? = await Transaction.latest(for: id),
                      transaction.revocationDate == nil, !transaction.isUpgraded,
                      (transaction.expirationDate ?? .distantFuture) > .now else { continue }
                found = transaction
            }
        }
        guard let found else {
            state = .none
            return
        }
        var renews = true
        var retrying = false
        if let product = products.first(where: { $0.id == found.productID }),
           let statuses = try? await product.subscription?.status {
            for status in statuses {
                guard case let .verified(renewal) = status.renewalInfo, renewal.currentProductID == found.productID else { continue }
                // the renewal state has the last word: a plan the store calls expired or revoked is over
                if status.state == .expired || status.state == .revoked {
                    state = .none
                    return
                }
                renews = renewal.willAutoRenew
                retrying = status.state == .inBillingRetryPeriod
            }
        }
        state = retrying ? .billingRetry(productID: found.productID) : .active(productID: found.productID, renews: renews, until: found.expirationDate)
    }
}

/// what can go wrong with a subscription, said as the person would want to hear it
public enum SubscriptionError: Error, Equatable, Sendable, LocalizedError {
    case storeUnavailable
    case productsMissing
    case purchaseFailed
    case pending
    case unverified
    case restoreFailed
    case nothingToRestore

    public var errorDescription: String? {
        switch self {
        case .storeUnavailable: String(localized: "the app store cannot be reached. check the connection and try again.", bundle: .module)
        case .productsMissing: String(localized: "the plans are not available right now. try again later.", bundle: .module)
        case .purchaseFailed: String(localized: "the payment did not go through. nothing was charged.", bundle: .module)
        case .pending: String(localized: "the payment is waiting for approval. the plan opens when it is approved.", bundle: .module)
        case .unverified: String(localized: "the app store could not confirm the purchase. try restoring.", bundle: .module)
        case .restoreFailed: String(localized: "restoring did not work. check the connection and try again.", bundle: .module)
        case .nothingToRestore: String(localized: "this apple account has no plan to restore.", bundle: .module)
        }
    }
}

public extension Product {
    /// how often it charges, in words: "a month", "a year", "every 3 months"
    var brandPeriod: String? {
        guard let period = subscription?.subscriptionPeriod else { return nil }
        let one: String = switch period.unit {
        case .day: String(localized: "a day", bundle: .module)
        case .week: String(localized: "a week", bundle: .module)
        case .month: String(localized: "a month", bundle: .module)
        case .year: String(localized: "a year", bundle: .module)
        @unknown default: ""
        }
        guard period.value > 1 else { return one }
        let many: String = switch period.unit {
        case .day: String(localized: "days", bundle: .module)
        case .week: String(localized: "weeks", bundle: .module)
        case .month: String(localized: "months", bundle: .module)
        case .year: String(localized: "years", bundle: .module)
        @unknown default: ""
        }
        return String(format: String(localized: "every %lld %@", bundle: .module), period.value, many)
    }
}
