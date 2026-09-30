import SwiftUI
import LaaabsKit

/// every piece of the kit on one screen, on the studio's black, to compare against the apps and the
/// pencil canvas. `swift run Gallery` opens it; `swift run Gallery --png out.png` writes it to a file.
struct GalleryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
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
