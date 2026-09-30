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
                let renderer = ImageRenderer(content: GalleryView())
                renderer.scale = 2
                if let image = renderer.nsImage, let tiff = image.tiffRepresentation,
                   let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
                    try? png.write(to: URL(fileURLWithPath: args[i + 1]))
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
