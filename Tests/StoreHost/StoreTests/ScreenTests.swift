#if os(iOS)
import StoreKitTest
import SwiftUI
import Testing
import UIKit
import LaaabsKit

/// draws the app screens of the kit on the simulator, at a phone's size, into the folder SHOTS names
/// (`TEST_RUNNER_SHOTS=<folder> xcodebuild test ...`), to look at them. without SHOTS it does nothing.
@MainActor
@Suite(.serialized) struct ScreenTests {
    @Test func drawTheAppScreens() async throws {
        guard let folder = ProcessInfo.processInfo.environment["SHOTS"] else { return }
        let url = try #require(Bundle(for: ScreenMarker.self).url(forResource: "Plans", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        BrandFonts.register()
        Wordmark.appMark = .finaaance

        let subscription = Subscription(productIDs: ["com.laaabs.kit.monthly", "com.laaabs.kit.yearly"])
        await subscription.load()
        let terms = URL(string: "https://laaabs.com/finaaance/terms")!
        let privacy = URL(string: "https://laaabs.com/finaaance/privacy")!
        let promises = [
            PaywallPromise(symbol: "chart.pie", title: "every euro has a job", detail: "split each payslip into pots before you spend it."),
            PaywallPromise(symbol: "calendar", title: "the months ahead", detail: "see what is coming and what will be left."),
            PaywallPromise(symbol: "lock", title: "yours only", detail: "on your phone, no account, no tracking."),
        ]
        let pages = [
            OnboardingPage(title: "plan the money before it arrives", message: "finaaance splits every payslip into the pots you choose."),
            OnboardingPage(symbol: "calendar", title: "see the months ahead", message: "what is coming, what is left, month by month."),
            OnboardingPage(symbol: "lock", title: "only on this phone", message: "no account, no bank login, nothing sent anywhere."),
        ]
        try draw(PaywallView(subscription: subscription, promises: promises, terms: terms, privacy: privacy), "paywall", folder)
        try draw(BrandOnboarding(pages: pages) {}, "onboarding", folder)
        try draw(ScrollView {
            VStack(spacing: 24) {
                PlanSettings(subscription: subscription) {}
                HelpSettings(terms: terms, privacy: privacy)
                AboutSettings()
            }
            .padding(20)
        }
        .background(BrandColors.surface), "settings", folder)
        try draw(VStack(spacing: 12) {
            Button("subscribe") {}.buttonStyle(BrandButtonStyle(.wash, fill: true))
            Button("see the plans") {}.buttonStyle(BrandButtonStyle(.outline, fill: true))
            Button("open") {}.buttonStyle(BrandButtonStyle(.white, fill: true))
        }
        .padding(24)
        .frame(maxHeight: .infinity)
        .background(BrandColors.surface), "buttons", folder)
    }

    private func draw(_ view: some View, _ name: String, _ folder: String) throws {
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        window.overrideUserInterfaceStyle = .dark
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
        RunLoop.main.run(until: Date().addingTimeInterval(0.8))
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        try #require(image.pngData()).write(to: URL(fileURLWithPath: folder).appendingPathComponent("\(name).png"))
        window.isHidden = true
    }
}

private final class ScreenMarker {}
#endif
