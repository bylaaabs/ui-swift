import StoreKit
import SwiftUI

/// the settings every app that charges has, as three blocks to put at the end of its own settings:
/// the plan, help, and about. drawn on the studio's black, like the rest of the kit.
///
///     ScrollView {
///         VStack(spacing: 24) {
///             // the app's own settings
///             PlanSettings(subscription: subscription) { showPaywall = true }
///             HelpSettings(terms: terms, privacy: privacy)
///             AboutSettings()
///         }
///     }

/// the plan: what the person has, a way to get one, restore, and the store's own page to change or
/// cancel it
public struct PlanSettings: View {
    let subscription: Subscription
    let showPaywall: () -> Void

    #if os(iOS)
    @State private var managing = false
    #endif

    public init(subscription: Subscription, showPaywall: @escaping () -> Void) {
        self.subscription = subscription
        self.showPaywall = showPaywall
    }

    public var body: some View {
        BrandBlock(String(localized: "plan", bundle: .module)) {
            CardRows {
                HStack {
                    Text(summary).font(.brandBody).foregroundStyle(BrandColors.on)
                    Spacer()
                    if subscription.isActive {
                        #if os(iOS)
                        Button(String(localized: "manage", bundle: .module)) { managing = true }
                            .buttonStyle(BrandButtonStyle(.outline))
                        #endif
                    } else {
                        Button(String(localized: "see the plans", bundle: .module), action: showPaywall)
                            .buttonStyle(BrandButtonStyle(.wash))
                    }
                }
                BrandHLine()
                Button(String(localized: "restore a purchase", bundle: .module)) {
                    Task { await subscription.restore() }
                }
                .buttonStyle(.plain)
                .font(.brandCallout)
                .foregroundStyle(BrandColors.onSecondary)
                .disabled(subscription.isWorking)
                if let error = subscription.error {
                    Text(error.localizedDescription).font(.brandCaption).foregroundStyle(BrandColors.onSecondary)
                }
            }
        }
        #if os(iOS)
        .manageSubscriptionsSheet(isPresented: $managing)
        #endif
        .task { if case .unknown = subscription.state { await subscription.load() } }
    }

    private var summary: String {
        switch subscription.state {
        case .unknown: return String(localized: "checking the plan", bundle: .module)
        case .none: return String(localized: "no plan", bundle: .module)
        case let .billingRetry(id):
            return String(format: String(localized: "%@: the payment is being retried", bundle: .module), name(id))
        case let .active(id, renews, until):
            guard let until else { return name(id) }
            let date = until.formatted(date: .long, time: .omitted)
            let format = renews ? String(localized: "%@, renews on %@", bundle: .module) : String(localized: "%@, ends on %@", bundle: .module)
            return String(format: format, name(id), date)
        }
    }

    private func name(_ id: String) -> String {
        subscription.products.first { $0.id == id }?.displayName.lowercased() ?? String(localized: "your plan", bundle: .module)
    }
}

/// help: write to support, and the terms and privacy pages
public struct HelpSettings: View {
    let terms: URL
    let privacy: URL

    private var calloutSize: CGFloat {
        #if os(iOS)
        16
        #else
        12
        #endif
    }

    public init(terms: URL, privacy: URL) {
        self.terms = terms
        self.privacy = privacy
    }

    public var body: some View {
        BrandBlock(String(localized: "help", bundle: .module)) {
            CardRows {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "write to us", bundle: .module)).font(.brandBody).foregroundStyle(BrandColors.on)
                    Text(String(localized: "questions, problems, ideas.", bundle: .module)).font(.brandCaption).foregroundStyle(BrandColors.onSecondary)
                    // the address draws the studio's name, never types it
                    Link(destination: URL(string: "mailto:support@laaabs.com")!) {
                        Text.name("support@laaabs.com", size: calloutSize, color: BrandColors.accent)
                            .font(.brandCallout)
                            .foregroundStyle(BrandColors.accent)
                    }
                    .padding(.top, 6)
                    .accessibilityLabel("support@laaabs.com")
                }
                BrandHLine()
                HStack(spacing: 18) {
                    BrandLink(title: String(localized: "terms", bundle: .module), url: terms.absoluteString, font: .brandCallout)
                    BrandLink(title: String(localized: "privacy", bundle: .module), url: privacy.absoluteString, font: .brandCallout)
                }
            }
        }
    }
}

/// about: the app's mark, its version, and "an app by laaabs." with the studio's name drawn
public struct AboutSettings: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 10) {
            Wordmark(height: 28)
            Text(verbatim: version).font(.brandCaption).foregroundStyle(BrandColors.onSecondary)
            Text("\(String(localized: "an app by", bundle: .module)) \(Text.laaabs(size: captionSize))")
                .font(.brandCaption)
                .foregroundStyle(BrandColors.onSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .accessibilityElement(children: .combine)
    }

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return String(format: String(localized: "version %@ (%@)", bundle: .module), short, build)
    }

    private var captionSize: CGFloat {
        #if os(iOS)
        13
        #else
        11
        #endif
    }
}
