import SwiftUI
import AppKit
import FolioCore

@main
struct FolioPDFApp: App {
    @NSApplicationDelegateAdaptor(FolioAppDelegate.self) var delegate
    @StateObject private var model = AppModel.shared
    @StateObject private var language = LanguageStore.shared
    var body: some Scene {
        Settings { PreferencesView().environmentObject(language).tint(FolioTheme.accent) }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(L("Settings")) { delegate.showPreferences() }.keyboardShortcut(",")
            }
            CommandGroup(replacing: .newItem) {
                Button("FolioPDF") { delegate.showMainWindow() }.keyboardShortcut("n")
                Divider()
                Button(L("Add images…")) { model.chooseImages() }.keyboardShortcut("o").disabled(model.running || model.importing)
                Button(L("Add folder…")) { model.chooseFolder() }.keyboardShortcut("o", modifiers: [.command, .shift]).disabled(model.running || model.importing)
                Divider()
                Button(L("Create PDF…")) { model.chooseDestination() }.keyboardShortcut("e").disabled(model.assets.isEmpty || model.running || model.importing)
            }
        }
    }
}

@MainActor
final class FolioAppDelegate: NSObject, NSApplicationDelegate {
    static weak var current: FolioAppDelegate?
    weak var model: AppModel?
    private var mainWindow: NSWindow?
    private var preferencesWindow: NSWindow?
    private var smokeScheduled = false
    private var closeGuard: MainWindowCloseGuard?
    func protect(_ window: NSWindow) {
        if window.delegate is MainWindowCloseGuard { return }
        let guardDelegate = MainWindowCloseGuard(owner: self, original: window.delegate)
        closeGuard = guardDelegate
        window.delegate = guardDelegate
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.current = self
        model = AppModel.shared
        NSApp.setActivationPolicy(.regular)
        showMainWindow()
        NSApp.activate(ignoringOtherApps: true)
        scheduleSmokeTest()
    }
    func showMainWindow() {
        if mainWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1280, height: 820), styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
            window.title = "FolioPDF"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.contentMinSize = NSSize(width: 1080, height: 690)
            window.contentView = NSHostingView(rootView: MainWindowContent())
            window.center()
            window.setFrameAutosaveName("FolioPDFMainWindow")
            protect(window)
            mainWindow = window
        }
        mainWindow?.makeKeyAndOrderFront(nil)
    }
    func showPreferences() {
        if preferencesWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 530, height: 480), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: PreferencesView().environmentObject(LanguageStore.shared).tint(FolioTheme.accent))
            window.center()
            preferencesWindow = window
        }
        refreshWindowLocalization()
        preferencesWindow?.makeKeyAndOrderFront(nil)
    }
    func refreshWindowLocalization() { preferencesWindow?.title = L("Settings") }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return false
    }
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { false }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if model?.running == true {
            let alert = NSAlert()
            alert.messageText = L("A conversion is still running.")
            alert.informativeText = L("Wait for it to finish, or cancel the conversion before quitting.")
            alert.addButton(withTitle: L("Keep working"))
            alert.runModal()
            return .terminateCancel
        }
        if model?.bookmarkHasUnsavedChanges == true {
            let alert = NSAlert()
            alert.messageText = L("You have unsaved bookmark changes.")
            alert.informativeText = L("Save a copy from the Bookmarks workspace to keep your changes.")
            alert.addButton(withTitle: L("Keep editing"))
            alert.addButton(withTitle: L("Quit without saving"))
            return alert.runModal() == .alertSecondButtonReturn ? .terminateNow : .terminateCancel
        }
        return .terminateNow
    }
    func scheduleSmokeTest() {
        guard !smokeScheduled, ProcessInfo.processInfo.arguments.contains("--ui-smoke-test") else { return }
        smokeScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.runUISmokeTest() }
    }
    private func runUISmokeTest(attempt: Int = 0) {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "--snapshot"), args.indices.contains(index + 1) else { return }
        if args.contains("--settings-only") { showPreferences() }
        let trace = "Attempt \(attempt); windows: \(NSApp.windows.map { "\($0.frame) visible=\($0.isVisible)" }); model: \(model != nil)"
        try? trace.write(toFile: args[index + 1] + ".log", atomically: true, encoding: .utf8)
        let target = args.contains("--settings-only") ? preferencesWindow : NSApp.windows.first(where: { $0.frame.width >= 900 && $0.isVisible })
        guard let window = target, let view = window.contentView else {
            if attempt < 15 { DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.runUISmokeTest(attempt: attempt + 1) } }
            else if args.contains("--quit-after-snapshot") { NSApp.terminate(nil) }
            return
        }
        var reopenVerified = false
        if args.contains("--verify-reopen") {
            window.performClose(nil)
            let didClose = !window.isVisible
            showMainWindow()
            reopenVerified = didClose && window.isVisible && mainWindow === window
        }
        let reopenStatus = args.contains("--verify-reopen") ? String(reopenVerified) : "not requested"
        if let folderIndex = args.firstIndex(of: "--sample-folder"), args.indices.contains(folderIndex + 1) {
            model?.importURLs([URL(fileURLWithPath: args[folderIndex + 1])])
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            do {
                guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { throw NSError(domain: "FolioSmoke", code: 1, userInfo: [NSLocalizedDescriptionKey: "No bitmap for bounds \(view.bounds)"]) }
                view.cacheDisplay(in: view.bounds, to: bitmap)
                guard let data = bitmap.representation(using: .png, properties: [:]) else { throw NSError(domain: "FolioSmoke", code: 2) }
                try data.write(to: URL(fileURLWithPath: args[index + 1]))
                try "Rendered \(view.bounds), \(data.count) bytes; close protection: \(window.delegate is MainWindowCloseGuard); reopen verified: \(reopenStatus)".write(toFile: args[index + 1] + ".log", atomically: true, encoding: .utf8)
            } catch { try? error.localizedDescription.write(toFile: args[index + 1] + ".log", atomically: true, encoding: .utf8) }
            if args.contains("--quit-after-snapshot") { NSApp.terminate(nil) }
        }
    }
}

/// Guard window closure; the app retains the window so reopening preserves drafts.
@MainActor
private final class MainWindowCloseGuard: NSObject, NSWindowDelegate {
    weak var owner: FolioAppDelegate?
    let original: NSWindowDelegate?
    init(owner: FolioAppDelegate, original: NSWindowDelegate?) {
        self.owner = owner
        self.original = original
    }
    override func responds(to selector: Selector!) -> Bool {
        super.responds(to: selector) || (original?.responds(to: selector) ?? false)
    }
    override func forwardingTarget(for selector: Selector!) -> Any? {
        original?.responds(to: selector) == true ? original : super.forwardingTarget(for: selector)
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if owner?.model?.running == true {
            let alert = NSAlert()
            alert.messageText = L("A conversion is still running.")
            alert.informativeText = L("Wait for it to finish, or cancel the conversion before closing this window.")
            alert.addButton(withTitle: L("Keep working"))
            alert.runModal()
            return false
        }
        if owner?.model?.bookmarkHasUnsavedChanges == true {
            let alert = NSAlert()
            alert.messageText = L("You have unsaved bookmark changes.")
            alert.informativeText = L("Save a copy from the Bookmarks workspace to keep your changes.")
            alert.addButton(withTitle: L("Keep editing"))
            alert.addButton(withTitle: L("Close without saving"))
            guard alert.runModal() == .alertSecondButtonReturn else { return false }
        }
        let permitted = original?.windowShouldClose?(sender) ?? true
        return permitted
    }
}

private struct MainWindowContent: View {
    @ObservedObject private var language = LanguageStore.shared
    @AppStorage("appearance") private var appearance = "system"
    var body: some View {
        RootView()
            .environmentObject(AppModel.shared)
            .environmentObject(language)
            .environment(\.locale, Locale(identifier: language.resolvedLanguage))
            .environment(\.layoutDirection, language.layoutDirection)
            .tint(FolioTheme.accent)
            .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
    }
}
