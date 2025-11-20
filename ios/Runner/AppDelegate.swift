import UIKit
import Flutter
import GoogleMaps
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    let channelName: String = "PushNotificationChannel"
    var deviceToken: String = ""

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        GMSServices.provideAPIKey("AIzaSyCaDHmbTEr-TVnJY8dG0ZnzsoBH3Mzh4cE")

        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

        // Set up Push Notification channel
        let pushNotificationChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }

        pushNotificationChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "requestNotificationPermissions":
                self?.requestNotificationPermissions(result: result)
            case "registerForPushNotifications":
                self?.registerForPushNotifications(application: application, result: result)
            case "retrieveDeviceToken":
                self?.getDeviceToken(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Register custom plugin SecurityDetection
        SecurityDetection.register(with: controller.registrar(forPlugin: "SecurityDetection")!)

        // Register all plugins
        GeneratedPluginRegistrant.register(with: self)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Push Notification Handlers

    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        self.deviceToken = tokenParts.joined()
    }

    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Handle error if needed
    }

    private func requestNotificationPermissions(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                result(FlutterError(code: "PERMISSION_ERROR", message: "Failed to request permissions", details: error.localizedDescription))
                return
            }
            result(granted)
        }
    }

    private func registerForPushNotifications(application: UIApplication, result: @escaping FlutterResult) {
        application.registerForRemoteNotifications()
        result("Device Token registration initiated")
    }

    private func getDeviceToken(result: @escaping FlutterResult) {
        if deviceToken.isEmpty {
            result(FlutterError(code: "UNAVAILABLE", message: "Device token not available", details: nil))
        } else {
            result(deviceToken)
        }
    }

    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         willPresent notification: UNNotification,
                                         withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         didReceive response: UNNotificationResponse,
                                         withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        handleNotification(userInfo: userInfo)
        completionHandler()
    }

    private func handleNotification(userInfo: [AnyHashable: Any]) {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let pushNotificationChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
        if let customData = userInfo["customKey"] as? String {
            pushNotificationChannel.invokeMethod("onPushNotification", arguments: customData)
        }
    }

    // MARK: - Security Detection Plugin

    @objc class SecurityDetection: NSObject, FlutterPlugin {

        @objc static func register(with registrar: FlutterPluginRegistrar) {
            let channel = FlutterMethodChannel(name: "com.cmds.luvpark/root", binaryMessenger: registrar.messenger())
            let instance = SecurityDetection()
            registrar.addMethodCallDelegate(instance, channel: channel)
        }

        func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
            switch call.method {
            case "isRooted":
                result(isJailbroken())
            case "isEmulator":
                result(isEmulator())
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        private func isJailbroken() -> Bool {
            return checkJailbreakMethod1() || checkJailbreakMethod2() || checkJailbreakMethod3()
        }

        private func checkJailbreakMethod1() -> Bool {
            let jailbreakPaths = [
                "/Applications/Cydia.app",
                "/Library/MobileSubstrate/MobileSubstrate.dylib",
                "/bin/bash",
                "/usr/sbin/sshd",
                "/etc/apt"
            ]
            for path in jailbreakPaths {
                if FileManager.default.fileExists(atPath: path) {
                    print("Jailbreak binary found at: \(path)")
                    return true
                }
            }
            return false
        }

        private func checkJailbreakMethod2() -> Bool {
            let fileManager = FileManager.default
            return fileManager.fileExists(atPath: "/private/var/lib/apt") ||
                   fileManager.fileExists(atPath: "/private/var/stash")
        }

        private func checkJailbreakMethod3() -> Bool {
            return canOpenURL(urlString: "cydia://")
        }

        private func canOpenURL(urlString: String) -> Bool {
            if let url = URL(string: urlString) {
                return UIApplication.shared.canOpenURL(url)
            }
            return false
        }

        private func isEmulator() -> Bool {
            return TARGET_OS_SIMULATOR != 0
        }
    }
}
