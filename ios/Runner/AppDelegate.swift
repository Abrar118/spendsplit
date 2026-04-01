import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    excludeSensitiveContainersFromBackup()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func excludeSensitiveContainersFromBackup() {
    let fileManager = FileManager.default
    let appGroupId = "group.com.example.spendsplit"

    do {
      if let applicationSupport = fileManager.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
      ).first {
        if !fileManager.fileExists(atPath: applicationSupport.path) {
          try fileManager.createDirectory(
            at: applicationSupport,
            withIntermediateDirectories: true,
            attributes: nil
          )
        }
        try markExcludedFromBackup(applicationSupport)
      }

      if let libraryDirectory = fileManager.urls(
        for: .libraryDirectory,
        in: .userDomainMask
      ).first {
        let preferencesDirectory = libraryDirectory.appendingPathComponent(
          "Preferences",
          isDirectory: true
        )
        if fileManager.fileExists(atPath: preferencesDirectory.path) {
          try markExcludedFromBackup(preferencesDirectory)
        }
      }

      if let appGroupContainer = fileManager.containerURL(
        forSecurityApplicationGroupIdentifier: appGroupId
      ) {
        try markExcludedFromBackup(appGroupContainer)
      }
    } catch {
      NSLog("SpendSplit backup exclusion failed: %@", error.localizedDescription)
    }
  }

  private func markExcludedFromBackup(_ url: URL) throws {
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    var mutableUrl = url
    try mutableUrl.setResourceValues(values)
  }
}
