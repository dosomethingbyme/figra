import AppKit
import SwiftUI

@main
struct FigraApp: App {
    @NSApplicationDelegateAdaptor(FigraApplicationDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Figra") {
            FigraAppView()
        }
        .windowStyle(.titleBar)
    }
}

final class FigraApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
