import SwiftUI
import LaaabsKit
import LaaabsShortcuts
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let galleryCapture = Self("gallery.capture")
}

/// every piece of the kit on one screen, on the studio's black, to compare against the apps and the
/// pencil canvas. `swift run Gallery` opens it; `swift run Gallery --png out.png` writes it to a file.
struct GalleryView: View {
    @State private var toggle = true
    @State private var mode = "area"
    @State private var delay: UInt32 = 3
    @State private var name = "caaapture 2026-09-30 at 12.04"
    @State private var commands = "cd ~/code\ngit status"
    @State private var from = 22 * 60
    @State private var level: String?
    @State private var project: String? = "ui-swift"
    @State private var sound = "chime"
    @State private var search = ""
    @State private var reply = "yes, ship it. and then\nopen the pull request against feat/ios\nso paaager can pin it"
    @State private var key = "sk-laaabs-0000"
    @State private var page: Int? = 2
    @State private var tab = "pages"
    @State private var region = "eu-west-3"
    @State private var targets: Set<String> = ["mac"]
    @State private var order = "importance"

    private static let times = (0 ..< 48).map { BrandSelectOption(String(format: "%02d:%02d", $0 / 2, $0 % 2 * 30), value: $0 * 30) }
    private static let levels = ["info", "good", "decision", "attention", "important", "urgent"].map { BrandSelectOption($0, value: $0) }
    private static let levelSections = [BrandSelectSection(options: [BrandSelectOption("every level", value: String?.none)] + levels.map { BrandSelectOption($0.label, value: Optional($0.value)) })]
    private static let sounds = [
        BrandSelectSection("laaabs.", options: [BrandSelectOption("chime", value: "chime", symbol: "bell"), BrandSelectOption("knock", value: "knock", symbol: "hand.tap")]),
        BrandSelectSection("the system", options: [BrandSelectOption("glass", value: "glass", symbol: "speaker.wave.2"), BrandSelectOption("none", value: "none", symbol: "speaker.slash")]),
    ]
    private static let pages = [
        GalleryPage(id: 1, title: "tests failed on main", detail: "ui-swift - 2 min ago"),
        GalleryPage(id: 2, title: "merge the pull request?", detail: "paaager - 14 min ago"),
        GalleryPage(id: 3, title: "turn ended", detail: "laaabs.com - 1 h ago"),
        GalleryPage(id: 4, title: "which plan, monthly or yearly?", detail: "finaaance - yesterday"),
    ]

    private static let levelSwatches: [(String, Color, Color, [Color])] = [
        ("info", BrandColors.on, BrandColors.onGlyph, [BrandColors.surfaceHover, BrandColors.separator, BrandColors.border]),
        ("good", BrandColors.success, BrandColors.successGlyph, [BrandColors.successWash, BrandColors.successSoft, BrandColors.successTint, BrandColors.successStrong, BrandColors.successOutline]),
        ("decision", BrandColors.accent, BrandColors.accentGlyph, [BrandColors.accentWash, BrandColors.accentSoft, BrandColors.accentTint, BrandColors.accentStrong, BrandColors.accentOutline]),
        ("attention", BrandColors.attention, BrandColors.attentionGlyph, [BrandColors.attentionWash, BrandColors.attentionSoft, BrandColors.attentionTint, BrandColors.attentionStrong, BrandColors.attentionOutline]),
        ("important", BrandColors.important, BrandColors.importantGlyph, [BrandColors.importantWash, BrandColors.importantSoft, BrandColors.importantTint, BrandColors.importantStrong, BrandColors.importantOutline]),
        ("urgent", BrandColors.danger, BrandColors.dangerGlyph, [BrandColors.dangerWash, BrandColors.dangerSoft, BrandColors.dangerTint, BrandColors.dangerStrong, BrandColors.dangerOutline]),
    ]
    private static let tabs = [
        BrandTab("pages", symbol: "tray", value: "pages", selectedSymbol: "tray.fill", badge: 7),
        BrandTab("agents", symbol: "terminal", value: "agents"),
        BrandTab("team", symbol: "person.2", value: "team", badge: 120),
        BrandTab("settings", symbol: "gearshape", value: "settings"),
    ]
    private static let orders = [
        BrandChoice("importance, then newest", description: "urgent first; newest first within a level", value: "importance"),
        BrandChoice("newest first", value: "newest"),
        BrandChoice("oldest first", value: "oldest"),
        BrandChoice("waiting longest", description: "the agents stopped the longest, first", value: "waiting"),
        BrandChoice("by agent", description: "grouped by agent, then importance", value: "agent"),
        BrandChoice("by project", description: "grouped by project, then importance", value: "project"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            section("controls, as baaar, taaab and caaapture draw them") {
                BrandTitleRow(title: "settings")
                BrandBlock("general") {
                    BrandRow("launch at login", detail: "start with the mac") { BrandToggle(isOn: $toggle) }
                    BrandRow("mode") {
                        BrandSegmented(selection: $mode, options: [
                            .init(value: "area", label: "area"),
                            .init(value: "window", label: "window"),
                            .init(value: "screen", label: "screen"),
                        ])
                    }
                    BrandRow("delay") { BrandStepper(value: $delay, range: 0 ... 10, unit: "s") }
                    BrandRow("shortcut") { ShortcutField(name: .galleryCapture) }
                }
                HStack(spacing: 10) {
                    PillButton("primary", kind: .primary) {}
                    PillButton("secondary", kind: .secondary) {}
                    PillButton("destructive", kind: .destructive) {}
                }
                HStack(spacing: 12) {
                    BrandBadge(text: "alpha")
                    BrandStatusPill(text: "live")
                    BrandStatusPill(text: "paused", isLive: false)
                    BrandDot()
                    BrandDot(isOn: false)
                    ActionChip(label: "pin", isOn: true) {}
                    ActionChip(label: "copy", isOn: false) {}
                    BrandLink(title: "laaabs.com", url: "https://laaabs.com")
                }
                BrandCallout(systemImage: "info.circle", title: "screen recording", message: "caaapture needs it to see the screen. nothing leaves the mac.", actionTitle: "open settings") {}
                VStack(spacing: 0) {
                    BrandMenuRow(title: "copy", symbol: "doc.on.doc") {}
                    BrandHLine()
                    BrandMenuRow(title: "delete", symbol: "trash", isDestructive: true) {}
                }
                .frame(width: 220)
                .brandCard()
            }
            section("patterns the apps wrote on their own") {
                HStack(alignment: .top, spacing: 24) {
                    VStack(spacing: 2) {
                        BrandNavRow(symbol: "gearshape", title: "general", isSelected: true) {}
                        BrandNavRow(symbol: "keyboard", title: "shortcuts", isSelected: false) {}
                    }
                    .frame(width: 180)
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("", text: $name).brandField()
                        TextEditor(text: $commands).brandTextArea(height: 56)
                    }
                    .frame(width: 280)
                }
                CardRows {
                    PermissionRow(title: "microphone", badge: "required", message: "speaaak hears you only while the key is down.", systemImage: "mic", isGranted: true) {}
                    BrandHLine()
                    PermissionRow(title: "accessibility", badge: "optional", message: "to type the text where the cursor is.", systemImage: "accessibility", isGranted: false) {}
                }
                .frame(width: 560)
            }
            section("select, text field, list and progress (#12)") {
                HStack(alignment: .top, spacing: 32) {
                    VStack(alignment: .leading, spacing: 14) {
                        CardRows {
                            BrandRow("from", detail: "a time of day, as paaager's quiet hours") {
                                BrandSelect(selection: $from, options: Self.times, font: .brandDigits)
                            }
                            BrandHLine()
                            BrandRow("sound", detail: "sections and symbols") {
                                BrandSelect(selection: $sound, sections: Self.sounds)
                            }
                        }
                        HStack(spacing: 8) {
                            BrandSelect(selection: $level, every: "every level", options: Self.levels)
                            BrandSelect(selection: $project, every: "every project", options: ["paaager", "ui-swift"].map { BrandSelectOption($0, value: $0) })
                            BrandSelect("level", selection: $sound, sections: Self.sounds, style: .filter)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            BrandTextField("search pages", text: $search, clearable: true)
                            BrandTextField("answer in your own words", text: $reply, kind: .multiline(maxLines: 3))
                            BrandTextField("api key", text: $key, kind: .secure, clearable: true)
                            BrandTextField("disabled", text: .constant("read only")).disabled(true)
                        }
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 18) {
                                BrandProgress()
                                BrandProgress(size: 24)
                                BrandProgress(label: "loading pages")
                            }
                            BrandProgress(value: 0.42, label: "uploading the build")
                            BrandProgress(value: 1)
                        }
                    }
                    .frame(width: 400)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 14) {
                            BrandSelectMenu(sections: Self.sounds, selection: sound, highlighted: "glass") { _ in }
                                .frame(width: 180, height: BrandSelectMenu.height(for: Self.sounds))
                                .brandHairlineBorder(cornerRadius: 9, fill: BrandColors.surfaceElevated)
                            BrandSelectMenu(sections: Self.levelSections, selection: String?.none, highlighted: "urgent") { _ in }
                                .frame(width: 150, height: BrandSelectMenu.height(for: Self.levelSections))
                                .brandHairlineBorder(cornerRadius: 9, fill: BrandColors.surfaceElevated)
                        }
                        BrandList(sections: [
                            BrandListSection("today", items: Array(Self.pages.prefix(3))),
                            BrandListSection("yesterday", items: Array(Self.pages.suffix(1))),
                        ], selection: $page, actions: { _ in [BrandListAction("seen", symbol: "eye") {}] }) { page in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(page.title).font(.brandBody).foregroundStyle(BrandColors.on)
                                Text(page.detail).font(.brandCaption).foregroundStyle(BrandColors.onSecondary)
                            }
                        } empty: {
                            EmptyView()
                        }
                        .frame(height: 270)
                        .brandHairlineBorder(cornerRadius: 10, fill: BrandColors.surface)
                        BrandList([GalleryPage](), row: { _ in EmptyView() }) {
                            BrandEmptyState(symbol: "line.3.horizontal.decrease", title: "nothing matches", message: "change the filters or clear the search.", actionTitle: "clear filters") {}
                        }
                        .frame(height: 190)
                        .brandHairlineBorder(cornerRadius: 10, fill: BrandColors.surface)
                    }
                    .frame(width: 400)
                }
            }
            section("paaager's levels, the tab bar, choices and sheets (v5)") {
                HStack(spacing: 18) {
                    ForEach(Self.levelSwatches, id: \.0) { name, color, glyph, wash in
                        VStack(spacing: 6) {
                            Image(systemName: "questionmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(glyph)
                                .frame(width: 28, height: 28)
                                .background(color, in: Circle())
                            Text(name).font(.brandCaption).foregroundStyle(BrandColors.onSecondary)
                            HStack(spacing: 2) {
                                ForEach(Array(wash.enumerated()), id: \.offset) { _, step in
                                    RoundedRectangle(cornerRadius: 3).fill(step).frame(width: 12, height: 12)
                                }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("attention text").font(.brandCaption).foregroundStyle(BrandColors.attentionText)
                            .padding(.horizontal, 8).padding(.vertical, 3).background(BrandColors.attentionSoft, in: Capsule())
                        Text("important text").font(.brandCaption).foregroundStyle(BrandColors.importantText)
                            .padding(.horizontal, 8).padding(.vertical, 3).background(BrandColors.importantSoft, in: Capsule())
                    }
                }
                HStack(alignment: .top, spacing: 24) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 40)
                        BrandTabBar(selection: $tab, tabs: Self.tabs, action: BrandTabAction("new page", symbol: "square.and.pencil") {})
                            .padding(.bottom, 34)
                            .background(alignment: .bottom) { BrandColors.surfaceElevated.opacity(0.97).frame(height: 34) }
                    }
                    .frame(width: 390, height: 150)
                    .brandHairlineBorder(cornerRadius: 10, fill: BrandColors.surface)
                    VStack(spacing: 0) {
                        Spacer(minLength: 40)
                        BrandTabBar(selection: $tab, tabs: Self.tabs, style: .floating)
                    }
                    .frame(width: 390, height: 150)
                    .brandHairlineBorder(cornerRadius: 10, fill: BrandColors.surface)
                }
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 14) {
                        BrandChoiceList(selection: $region, choices: ["eu-west-1", "eu-west-3", "eu-central-1"].map { BrandChoice($0, value: $0) }, labelFont: .brandMono)
                        BrandChoiceList(selection: $targets, choices: [
                            BrandChoice("the mac", description: "the one you are using", value: "mac"),
                            BrandChoice("the iphone", description: "when you are away", value: "iphone"),
                            BrandChoice("pablo", value: "pablo"),
                        ])
                        BrandChoiceRow("disabled", description: "a choice that cannot be made now", isSelected: false) {}
                            .disabled(true)
                    }
                    .frame(width: 280)
                    BrandSheet("sort", hint: "the order is kept on this device. the Mac has the same list.", done: {}) {
                        BrandChoiceList(selection: $order, choices: Self.orders, style: .plain)
                    }
                    .frame(width: 300)
                    .brandHairlineBorder(cornerRadius: 14, fill: BrandColors.surfaceElevated)
                    BrandSheet {
                        BrandMenuList([
                            BrandListAction("open on github", symbol: "arrow.up.right.square") {},
                            BrandListAction("copy the link", symbol: "link") {},
                            BrandListAction("forget this page", symbol: "trash", destructive: true) {},
                        ])
                    }
                    .frame(width: 240)
                    .brandHairlineBorder(cornerRadius: 14, fill: BrandColors.surfaceElevated)
                }
            }
            section("the name in text: drawn, above; outfit typed, below, to check size, weight and baseline") {
                ForEach([13.0, 17.0, 40.0], id: \.self) { size in
                    HStack(alignment: .firstTextBaseline, spacing: 40) {
                        ForEach([(NameWeight.medium, Font.Weight.medium), (.semibold, .semibold), (.bold, .bold)], id: \.0.rawValue) { name, weight in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("things by \(Text.laaabs(size: size, weight: name))").font(.outfit(size, weight: weight))
                                Text(verbatim: "things by laaabs.").font(.outfit(size, weight: weight)).foregroundStyle(.white.opacity(0.35))
                            }
                        }
                    }
                    .foregroundStyle(.white)
                }
                Text.name("hello@laaabs.com - bylaaabs on github - a tool by laaabs.", size: 13)
                    .font(.outfit(13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            section("the studio") {
                Wordmark(.laaabs, height: 64)
                Wordmark(.laaabs, height: 26, dot: .ink)
                Wordmark(.thingsByLaaabs, height: 20)
            }
            section("tools") {
                ForEach([WordmarkName.baaar, .haaarness, .speaaak, .islaaand, .clipboaaard, .terminaaal, .taaab, .caaapture], id: \.self) { name in
                    row(name)
                }
            }
            section("apps") {
                row(.finaaance)
            }
        }
        .padding(40)
        .frame(width: 960, alignment: .leading)
        .background(Color(red: 10 / 255, green: 10 / 255, blue: 10 / 255))
    }

    private func row(_ name: WordmarkName) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 24) {
            Wordmark(name, height: 30)
            Wordmark(name, height: 14)
            if Wordmarks.data(name).draft {
                Text("draft").font(.system(size: 11, design: .monospaced)).foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    private func section(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.system(size: 11, design: .monospaced)).foregroundStyle(.white.opacity(0.4))
            content()
        }
    }
}

struct GalleryPage: Identifiable {
    let id: Int
    let title: String
    let detail: String
}

@main
struct GalleryApp: App {
    init() {
        MainActor.assumeIsolated {
            BrandFonts.register()
            BrandMonoFont.register()
            Wordmark.appMark = .laaabs
        }
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--png"), i + 1 < args.count {
            MainActor.assumeIsolated {
                // drawn as the apps draw their render checks: an AppKit host, so text fields and other
                // AppKit-backed controls come out too (ImageRenderer leaves them as placeholders)
                let host = NSHostingView(rootView: GalleryView())
                host.frame.size = host.fittingSize
                let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
                window.contentView = host
                host.layoutSubtreeIfNeeded()
                if let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) {
                    host.cacheDisplay(in: host.bounds, to: rep)
                    try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: args[i + 1]))
                    print("wrote \(args[i + 1])")
                }
            }
            exit(0)
        }
    }

    var body: some Scene {
        WindowGroup("laaabs. kit") { ScrollView { GalleryView() } }
    }
}
