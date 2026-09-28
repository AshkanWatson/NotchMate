import SwiftUI

@main
struct NotchMateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("NotchMate", systemImage: "rectangle.topthird.inset.filled") {
            MenuBarContent(controller: appDelegate.controller, openSettings: appDelegate.showSettings)
        }
    }
}
