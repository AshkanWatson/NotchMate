import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var controller: NotchController
    let openSettings: @MainActor () -> Void

    var body: some View {
        let title = controller.state == .expanded ? "Collapse Notch" : "Expand Notch"
        Button(title) {
            controller.toggle()
        }
        .disabled(controller.layout == nil)
        Text(controller.statusDescription)
        Divider()
        Button("Settings…", action: openSettings)
            .keyboardShortcut(",")
        Button("About NotchMate") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.orderFrontStandardAboutPanel(nil)
        }
        Divider()
        Button("Quit NotchMate") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
