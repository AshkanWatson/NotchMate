import SwiftUI
import NotchMateKit

/// Root of the notch panel. The window never resizes; this view animates the
/// notch shape between its collapsed and expanded rectangles inside it.
struct NotchRootView: View {
    @ObservedObject var controller: NotchController
    @ObservedObject var settingsModel: SettingsModel
    @ObservedObject var battery: BatteryMonitor
    @ObservedObject var nowPlaying: NowPlayingService
    @Environment(\.colorScheme) private var systemColorScheme

    var body: some View {
        if let layout = controller.layout {
            notch(in: layout)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                // On notched displays AppKit reports the camera housing as a top safe-area
                // inset for windows covering it; the notch view must draw right into it.
                .ignoresSafeArea()
        }
    }

    private func notch(in layout: NotchLayout) -> some View {
        let expanded = controller.state == .expanded
        let rect = expanded ? layout.localExpandedRect : layout.localNotchRect
        let shape = expanded ? NotchShape.expanded : NotchShape.collapsed
        let usesSystemAppearance = settingsModel.settings.appearance == .system

        return ZStack(alignment: .top) {
            shape
                .fill(expanded && usesSystemAppearance ? Color(nsColor: .windowBackgroundColor) : Color.black)
                .shadow(color: .black.opacity(expanded ? 0.35 : 0), radius: 18, y: 8)
                .accessibilityElement()
                .accessibilityLabel(expanded ? "NotchMate panel" : "NotchMate")
                .accessibilityIdentifier(expanded ? "notch.expanded" : "notch.compact")

            if expanded {
                ExpandedContentView(
                    notchSize: layout.notchRect.size,
                    sideInset: shape.topRadius,
                    settings: settingsModel.settings,
                    battery: battery.info,
                    nowPlaying: nowPlaying,
                    openSettings: controller.openSettings
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipShape(shape)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.92, anchor: .top)).animation(.easeOut(duration: 0.25).delay(0.06)),
                    removal: .opacity.animation(.easeIn(duration: 0.12))
                ))
            }
        }
        .frame(width: rect.width, height: rect.height)
        .environment(\.colorScheme, usesSystemAppearance ? systemColorScheme : .dark)
        // Padding (rather than offset) keeps accessibility frames accurate.
        .padding(.leading, rect.minX)
        .padding(.top, rect.minY)
    }
}
