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
        BrandMonoFont.register()
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
        try draw(ControlsShot(), "controls", folder)
        try draw(SelectSheetShot(), "select-sheet", folder)
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

private struct ShotPage: Identifiable {
    let id: Int
    let title: String
    let detail: String
}

/// the select, the text field, the list and the progress at a phone's size (#12)
private struct ControlsShot: View {
    @State private var from = 22 * 60
    @State private var level: String? = "urgent"
    @State private var project: String?
    @State private var search = "deploy"
    @State private var reply = "yes, ship it.\nand open the pull request"
    @State private var key = "sk-laaabs-0000"
    @State private var page: Int? = 2

    private let times = (0 ..< 48).map { BrandSelectOption(String(format: "%02d:%02d", $0 / 2, $0 % 2 * 30), value: $0 * 30) }
    private let levels = ["info", "decision", "urgent", "call"].map { BrandSelectOption($0, value: $0) }
    private let pages = [
        ShotPage(id: 1, title: "tests failed on main", detail: "ui-swift - 2 min ago"),
        ShotPage(id: 2, title: "merge the pull request?", detail: "paaager - 14 min ago"),
        ShotPage(id: 3, title: "turn ended", detail: "laaabs.com - 1 h ago"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("quiet from").font(.brandBody).foregroundStyle(BrandColors.on)
                Spacer()
                BrandSelect(selection: $from, options: times, font: .brandDigits)
            }
            HStack(spacing: 8) {
                BrandSelect(selection: $level, every: "every level", options: levels)
                BrandSelect(selection: $project, every: "every project", options: [BrandSelectOption("paaager", value: "paaager")])
            }
            BrandTextField("search pages", text: $search, clearable: true)
            BrandTextField("answer in your own words", text: $reply, kind: .multiline(maxLines: 4))
            BrandTextField("api key", text: $key, kind: .secure)
            HStack(spacing: 16) {
                BrandProgress(size: 20)
                BrandProgress(value: 0.42, label: "uploading the build")
            }
            BrandList(pages, selection: $page, actions: { _ in [BrandListAction("seen", symbol: "eye") {}] }) { page in
                VStack(alignment: .leading, spacing: 2) {
                    Text(page.title).font(.brandBody).foregroundStyle(BrandColors.on)
                    Text(page.detail).font(.brandCaption).foregroundStyle(BrandColors.onSecondary)
                }
            }
            .frame(height: 230)
            .padding(.horizontal, -20)
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(BrandColors.surface)
    }
}

/// the options as the sheet shows them when a select is tapped on iOS
private struct SelectSheetShot: View {
    private let levels = [BrandSelectSection<String?>(options: [BrandSelectOption("every level", value: nil)] + ["info", "decision", "urgent", "call"].map { BrandSelectOption($0, value: Optional($0)) })]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                Capsule().fill(BrandColors.onTertiary).frame(width: 36, height: 5).frame(maxWidth: .infinity).padding(.top, 6)
                Text("level").font(.brandHeadline).foregroundStyle(BrandColors.on).padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 8)
                BrandSelectMenu(sections: levels, selection: Optional("urgent")) { _ in }
                    .frame(height: BrandSelectMenu.height(for: levels))
                    .padding(.horizontal, 6)
                    .padding(.bottom, 30)
            }
            .background(BrandColors.surfaceElevated, in: UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
        }
        .background(BrandColors.surface)
    }
}
#endif
