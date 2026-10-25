import SwiftUI

/// one screen of the first run
public struct OnboardingPage: Identifiable, Sendable {
    public let id = UUID()
    public let symbol: String?
    public let title: String
    public let message: String

    public init(symbol: String? = nil, title: String, message: String) {
        self.symbol = symbol
        self.title = title
        self.message = message
    }
}

/// the first run, as the handbook asks: four screens at most, each one thing, skippable from any of
/// them, and still when the person asks for reduced motion. the first screen carries the app's mark
/// and "an app by laaabs."; the last one's button finishes.
///
///     BrandOnboarding(pages: pages) { hasSeenOnboarding = true }
public struct BrandOnboarding: View {
    /// the handbook's rule: an onboarding longer than this is a manual nobody reads
    public static let maximumPages = 4

    let pages: [OnboardingPage]
    let onFinish: () -> Void

    @State private var index = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// pages past the fourth are left out (and a debug build stops, to catch it early)
    public init(pages: [OnboardingPage], onFinish: @escaping () -> Void) {
        assert(pages.count <= Self.maximumPages, "an onboarding has four screens at most")
        self.pages = Array(pages.prefix(Self.maximumPages))
        self.onFinish = onFinish
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if index < pages.count - 1 {
                    Button(String(localized: "skip", bundle: .module), action: onFinish)
                        .buttonStyle(.plain)
                        .font(.brandCaption)
                        .foregroundStyle(BrandColors.onSecondary)
                }
            }
            .frame(height: 44)

            Spacer(minLength: 24)
            if let page = pages[safe: index] {
                screen(page, first: index == 0)
                    .id(page.id)
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .offset(y: 12)))
            }
            Spacer(minLength: 24)

            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { i in
                    BrandDot(isOn: i == index)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(format: String(localized: "screen %lld of %lld", bundle: .module), index + 1, pages.count))
            .padding(.bottom, 20)

            Button(index < pages.count - 1 ? String(localized: "next", bundle: .module) : String(localized: "start", bundle: .module)) {
                if index < pages.count - 1 {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) { index += 1 }
                } else {
                    onFinish()
                }
            }
            .buttonStyle(BrandButtonStyle(.wash, fill: true))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(BrandColors.surface.ignoresSafeArea())
    }

    private func screen(_ page: OnboardingPage, first: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if first {
                Wordmark(height: 36)
                Text("\(String(localized: "an app by", bundle: .module)) \(Text.laaabs(size: 17))")
                    .font(.brandBody)
                    .foregroundStyle(BrandColors.onSecondary)
                    .padding(.bottom, 12)
            } else if let symbol = page.symbol {
                Image(systemName: symbol)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(BrandColors.accent)
                    .padding(.bottom, 8)
            }
            Text(page.title).font(.brandTitle).foregroundStyle(BrandColors.on)
            Text(page.message).font(.brandBody).foregroundStyle(BrandColors.onSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
