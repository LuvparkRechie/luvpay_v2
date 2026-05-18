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

        GeneratedPluginRegistrant.register(with: self)

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in
            String(format: "%02.2hhx", data)
        }
        self.deviceToken = tokenParts.joined()
    }

    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register: \(error.localizedDescription)")
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)

        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("Failed to reset badge count: \(error)")
                }
            }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    func requestNotificationPermissions(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                result(
                    FlutterError(
                        code: "PERMISSION_ERROR",
                        message: "Failed to request permissions",
                        details: error.localizedDescription
                    )
                )
                return
            }

            result(granted)
        }
    }

    func registerForPushNotifications(
        application: UIApplication,
        result: @escaping FlutterResult
    ) {
        application.registerForRemoteNotifications()
        result("Device Token registration initiated")
    }

    func getDeviceToken(result: @escaping FlutterResult) {
        if deviceToken.isEmpty {
            result(
                FlutterError(
                    code: "UNAVAILABLE",
                    message: "Device token not available",
                    details: nil
                )
            )
        } else {
            result(deviceToken)
        }
    }
}

// MARK: - Security Detection Plugin

@objc class SecurityDetection: NSObject, FlutterPlugin {

    @objc static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.cmds.luvpay/root",
            binaryMessenger: registrar.messenger()
        )
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
        return checkJailbreakMethod1()
            || checkJailbreakMethod2()
            || checkJailbreakMethod3()
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
                return true
            }
        }

        return false
    }

    private func checkJailbreakMethod2() -> Bool {
        let fileManager = FileManager.default

        return fileManager.fileExists(atPath: "/private/var/lib/apt")
            || fileManager.fileExists(atPath: "/private/var/stash")
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
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}