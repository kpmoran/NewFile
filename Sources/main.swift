import Cocoa

/// One-shot Finder toolbar app. Cmd-drag NewFile.app into a Finder window's toolbar; clicking it
/// launches the app, which creates "NewFile.txt" in that window's folder, selects it, and quits.
/// Also works from the Dock, Spotlight, or `open -a NewFile`.
/// Never shows dialogs; problems are written to ~/Library/Logs/NewFile.log.

private let logURL = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Logs/NewFile.log")

private func log(_ message: String) {
    let line = "\(Date()) \(message)\n"
    NSLog("%@", message)
    if let handle = try? FileHandle(forWritingTo: logURL) {
        handle.seekToEndOfFile()
        handle.write(line.data(using: .utf8)!)
        handle.closeFile()
    } else {
        try? line.write(to: logURL, atomically: true, encoding: .utf8)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        createNewFile()
        NSApp.terminate(nil)
    }

    /// If a copy is somehow still running when the toolbar icon is clicked again, Finder sends a
    /// "reopen" event instead of launching; treat it the same as a click.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        createNewFile()
        NSApp.terminate(nil)
        return false
    }

    private func createNewFile() {
        guard let folder = frontFinderFolder() else {
            NSSound.beep()
            return
        }
        let url = uniqueURL(in: folder, baseName: "NewFile", ext: "txt")
        do {
            try Data().write(to: url, options: .withoutOverwriting)
            log("created \(url.path)")
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            log("could not create \(url.path): \(error.localizedDescription)")
            NSSound.beep()
        }
    }

    /// Asks Finder for the folder shown in its frontmost window. Falls back to the Desktop
    /// when no Finder windows are open (that's what Finder itself treats as "current").
    private func frontFinderFolder() -> URL? {
        let script = """
        tell application "Finder"
            if (count of Finder windows) > 0 then
                return POSIX path of (target of front Finder window as alias)
            else
                return POSIX path of (desktop as alias)
            end if
        end tell
        """
        var errorInfo: NSDictionary?
        guard let apple = NSAppleScript(source: script) else { return nil }
        let result = apple.executeAndReturnError(&errorInfo)
        if let errorInfo {
            // -1743 means NewFile is not allowed to control Finder:
            // System Settings > Privacy & Security > Automation > NewFile > Finder.
            log("Finder AppleScript error: \(errorInfo)")
            return nil
        }
        guard let path = result.stringValue, !path.isEmpty else {
            log("Finder returned no path")
            return nil
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    /// NewFile.txt, then NewFile 2.txt, NewFile 3.txt, ... if it already exists.
    private func uniqueURL(in folder: URL, baseName: String, ext: String) -> URL {
        let fm = FileManager.default
        var candidate = folder.appendingPathComponent("\(baseName).\(ext)")
        var n = 2
        while fm.fileExists(atPath: candidate.path) {
            candidate = folder.appendingPathComponent("\(baseName) \(n).\(ext)")
            n += 1
        }
        return candidate
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // no Dock icon, no menu bar takeover
app.run()
