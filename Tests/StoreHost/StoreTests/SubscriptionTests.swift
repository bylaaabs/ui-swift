import Foundation
import StoreKit
import StoreKitTest
import Testing
import LaaabsKit

/// the subscription layer against storekit's local test store: two plans, bought and read back
@MainActor
@Suite(.serialized) struct SubscriptionTests {
    let session: SKTestSession
    let ids = ["com.laaabs.kit.monthly", "com.laaabs.kit.yearly"]

    init() throws {
        let url = try #require(Bundle(for: Marker.self).url(forResource: "Plans", withExtension: "storekit"))
        session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
    }

    @Test func thePlansComeFromTheStoreCheapestFirst() async {
        let subscription = Subscription(productIDs: ids)
        await subscription.load()
        #expect(subscription.products.map(\.id) == ids)
        #expect(subscription.products.first?.brandPeriod == "a month")
        #expect(subscription.products.last?.brandPeriod == "a year")
        #expect(subscription.state == .none)
        #expect(!subscription.isActive)
    }

    @Test func buyingAPlanOpensIt() async throws {
        let subscription = Subscription(productIDs: ids)
        await subscription.load()
        let monthly = try #require(subscription.products.first)
        #expect(await subscription.purchase(monthly))
        #expect(subscription.isActive)
        guard case let .active(id, renews, until) = subscription.state else {
            Issue.record("expected an active plan, got \(subscription.state)")
            return
        }
        #expect(id == monthly.id)
        #expect(renews)
        #expect(until != nil)
    }

    // storekit's local store on macOS never moves an expired plan's date; on iOS it does, a moment later
    #if os(iOS)
    @Test func anExpiredPlanClosesAgain() async throws {
        let subscription = Subscription(productIDs: ids)
        await subscription.load()
        let monthly = try #require(subscription.products.first)
        #expect(await subscription.purchase(monthly))
        try session.expireSubscription(productIdentifier: monthly.id)
        // the store takes a moment; in an app, Transaction.updates refreshes on its own
        for _ in 0 ..< 20 where subscription.state != .none {
            try await Task.sleep(for: .milliseconds(250))
            await subscription.refresh()
        }
        #expect(subscription.state == .none)
        #expect(!subscription.isActive)
    }
    #endif

    @Test func aFailedPurchaseSaysSoInPlainWords() async throws {
        session.failTransactionsEnabled = true
        session.failureError = .unknown
        defer { session.failTransactionsEnabled = false }
        let subscription = Subscription(productIDs: ids)
        await subscription.load()
        let monthly = try #require(subscription.products.first)
        #expect(await subscription.purchase(monthly) == false)
        #expect(subscription.error == .purchaseFailed)
        #expect(!subscription.isActive)
    }
}


/// finds this test bundle, where the local store's configuration is
private final class Marker {}
