#if os(macOS)
// a shortcut recorder in the laaabs. look, lowercase in every language: KeyboardShortcuts' own
// recorder is a final search field with capitalised placeholders ("Record Shortcut"), so caaapture
// draws its own on the package's public api. click to record, press the shortcut; escape cancels,
// delete clears. global shortcuts are paused while recording, so the one being set does not fire.

import AppKit
@preconcurrency import KeyboardShortcuts
import SwiftUI
import LaaabsKit

public struct ShortcutField: View {
    public init(name: KeyboardShortcuts.Name) { self.name = name }

    public let name: KeyboardShortcuts.Name

    @State private var shortcut: KeyboardShortcuts.Shortcut?
    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var isHovered = false

    public var body: some View {
        HStack(spacing: 6) {
            Button(action: toggle) {
                Group {
                    if isRecording {
                        HStack(spacing: 6) {
                            BrandDot(size: 5)
                            Text("press the keys")
                                .font(.outfit(12, weight: .semibold))
                                .foregroundStyle(BrandColors.on)
                        }
                    } else if let shortcut {
                        Text(verbatim: shortcut.description)
                            .font(.brandDigits)
                            .foregroundStyle(BrandColors.on)
                    } else {
                        Text("add")
                            .font(.brandCallout)
                            .foregroundStyle(BrandColors.onSecondary)
                    }
                }
                .frame(width: 118, height: 28)
                .background(isRecording ? BrandColors.accentSoft : (isHovered ? BrandColors.surfaceField : .clear), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(isRecording ? BrandColors.accentTint : BrandColors.on.opacity(0.15), lineWidth: 1))
                .contentShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }

            Button {
                KeyboardShortcuts.setShortcut(nil, for: name)
                shortcut = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(BrandColors.onSecondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .opacity(shortcut == nil || isRecording ? 0 : 1)
            .help(String(localized: "clear"))
            .accessibilityLabel(Text("clear"))
        }
        .onAppear { shortcut = KeyboardShortcuts.getShortcut(for: name) }
        .onDisappear(perform: stop)
        .accessibilityElement(children: .contain)
    }

    private func toggle() {
        isRecording ? stop() : start()
    }

    private func start() {
        isRecording = true
        KeyboardShortcuts.isEnabled = false
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            MainActor.assumeIsolated { record(event) }
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
        KeyboardShortcuts.isEnabled = true
    }

    private func record(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        switch event.keyCode {
        case 53 where modifiers.isEmpty: // escape
            stop()
        case 51 where modifiers.isEmpty, 117 where modifiers.isEmpty: // delete, forward delete
            KeyboardShortcuts.setShortcut(nil, for: name)
            shortcut = nil
            stop()
        default:
            // a global shortcut needs a modifier other than shift alone, as the system's.
            guard !modifiers.subtracting(.shift).isEmpty, let recorded = KeyboardShortcuts.Shortcut(event: event) else {
                NSSound.beep()
                return
            }
            KeyboardShortcuts.setShortcut(recorded, for: name)
            shortcut = recorded
            stop()
        }
    }
}
#endif
