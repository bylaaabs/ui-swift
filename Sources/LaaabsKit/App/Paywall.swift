import StoreKit
import SwiftUI

/// one thing a plan gives, as the paywall lists it
public struct PaywallPromise: Identifiable, Sendable {
    public let id = UUID()
    public let symbol: String
    public let title: String
    public let detail: String

    public init(symbol: String, title: String, detail: String) {
        self.symbol = symbol
        self.title = title
        self.detail = detail
    }
}

/// the screen that asks for a plan: the app's mark, what you get, the plans at the store's prices
/// (never typed), one wash button, restore, and the terms and privacy links. lowercase throughout;
/// the cyan wash only on the button.
///
///     PaywallView(subscription: subscription, promises: promises,
///                 terms: URL(string: "https://laaabs.com/finaaance/terms")!,
///                 privacy: URL(string: "https://laaabs.com/finaaance/privacy")!)
public struct PaywallView: View {
    let subscription: Subscription
    let promises: [PaywallPromise]
    let terms: URL
    let privacy: URL
    let onDone: (() -> Void)?

    @State private var chosen: Product.ID?

    public init(subscription: Subscription, promises: [PaywallPromise], terms: URL, privacy: URL, onDone: (() -> Void)? = nil) {
        self.subscription = subscription
        self.promises = promises
        self.terms = terms
        self.privacy = privacy
        self.onDone = onDone
        // the longest plan comes chosen: it is the cheapest by the month
        _chosen = State(initialValue: subscription.products.last?.id)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Wordmark(height: 30)
                    .padding(.top, 24)
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(promises) { promise in
                        HStack(alignment: .firstTextBaseline, spacing: 14) {
                            Image(systemName: promise.symbol)
                                .font(.brandBody)
                                .foregroundStyle(BrandColors.accent)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(promise.title).font(.brandHeadline).foregroundStyle(BrandColors.on)
                                Text(promise.detail).font(.brandCallout).foregroundStyle(BrandColors.onSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                plans
                VStack(spacing: 14) {
                    Button(String(localized: "subscribe", bundle: .module)) {
                        guard let product = chosenProduct else { return }
                        Task {
                            if await subscription.purchase(product) { onDone?() }
                        }
                    }
                    .buttonStyle(BrandButtonStyle(.wash, fill: true))
                    .disabled(chosenProduct == nil || subscription.isWorking)

                    if let error = subscription.error {
                        Text(error.localizedDescription)
                            .font(.brandCaption)
                            .foregroundStyle(BrandColors.onSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    Text(String(localized: "renews until you cancel. cancel any time in the app store's settings.", bundle: .module))
                        .font(.brandCaption)
                        .foregroundStyle(BrandColors.onTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    HStack(spacing: 18) {
                        Button(String(localized: "restore", bundle: .module)) {
                            Task {
                                await subscription.restore()
                                if subscription.isActive { onDone?() }
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.brandCaption)
                        .foregroundStyle(BrandColors.onSecondary)
                        .disabled(subscription.isWorking)
                        BrandLink(title: String(localized: "terms", bundle: .module), url: terms.absoluteString, color: BrandColors.onSecondary)
                        BrandLink(title: String(localized: "privacy", bundle: .module), url: privacy.absoluteString, color: BrandColors.onSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(BrandColors.surface.ignoresSafeArea())
        .task {
            if subscription.products.isEmpty { await subscription.load() }
            if chosen == nil { chosen = subscription.products.last?.id }
        }
        .onChange(of: subscription.products.map(\.id)) { _, ids in
            if chosen == nil { chosen = ids.last }
        }
    }

    private var chosenProduct: Product? {
        subscription.products.first { $0.id == chosen }
    }

    private var plans: some View {
        VStack(spacing: 10) {
            ForEach(subscription.products, id: \.id) { product in
                let isChosen = product.id == chosen
                Button {
                    chosen = product.id
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.displayName.lowercased()).font(.brandBody).foregroundStyle(BrandColors.on)
                            if let period = product.brandPeriod {
                                Text(period).font(.brandCaption).foregroundStyle(BrandColors.onSecondary)
                            }
                        }
                        Spacer()
                        Text(product.displayPrice).font(.brandHeadline).foregroundStyle(BrandColors.on)
                    }
                    .padding(16)
                    .background(isChosen ? BrandColors.accent.opacity(0.06) : BrandColors.surfaceElevated,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isChosen ? BrandColors.accent.opacity(0.6) : BrandColors.border, lineWidth: 1))
                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isChosen ? .isSelected : [])
            }
            if subscription.products.isEmpty, subscription.error == nil {
                ProgressView().tint(BrandColors.onSecondary).frame(maxWidth: .infinity).padding(.vertical, 20)
            }
        }
    }
}
