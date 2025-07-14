import Foundation
import ServiceManagement

class LaunchHelper {
    static let shared = LaunchHelper()
    
    private let launcherBundleId = "com.yourcompany.WPMonitorLauncher"
    
    var isLaunchAtLoginEnabled: Bool {
        get {
            return SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error)")
            }
        }
    }
    
    func toggleLaunchAtLogin() {
        isLaunchAtLoginEnabled.toggle()
    }
}
