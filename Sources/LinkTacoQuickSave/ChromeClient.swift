import AppKit
import Foundation

enum ChromeClientError: Error {
    case noResult
    case scriptFailure(String)
}

struct ChromeTabInfo {
    let url: String
    let title: String
    let selectedText: String
}

enum ChromeClient {
    static func getActiveTab() throws -> ChromeTabInfo {
        let source = #"""
        tell application "Google Chrome"
            if not (exists front window) then error "No Chrome window available"
            set activeTab to active tab of front window
            set pageURL to URL of activeTab
            set pageTitle to title of activeTab
            return pageURL & "|||" & pageTitle
        end tell
        """#

        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw ChromeClientError.scriptFailure("Failed to initialize AppleScript")
        }

        let output = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            throw ChromeClientError.scriptFailure(errorInfo.description)
        }

        guard let payload = output.stringValue else {
            throw ChromeClientError.noResult
        }

        let parts = payload.components(separatedBy: "|||")
        let url = parts.first ?? ""
        let title = parts.count > 1 ? parts[1] : ""

        return ChromeTabInfo(url: url, title: title, selectedText: "")
    }
}
