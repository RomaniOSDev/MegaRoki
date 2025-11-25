//
//  OneSignalService.swift
//  BubblyBass
//
//  Created by Роман Главацкий on 26.10.2025.
//

import Foundation
import OneSignalFramework
import Combine
import AppsFlyerLib
import UIKit

@MainActor
final class OneSignalService: NSObject, ObservableObject {
    
    static let shared = OneSignalService()
    private var isInitialized = false
    private let appsFlyerId = AppsFlyerLib.shared().getAppsFlyerUID()
    
    private override init() {}
    
    // MARK: - Initialize OneSignal when needed
    func initializeIfNeeded() {
        guard !isInitialized else { return }
        
        OneSignal.initialize("2b317b7a-7ca6-4b06-b563-d3fb102ccfed", withLaunchOptions: nil)
        OneSignal.login(appsFlyerId)
        //OneSignal.Notifications.clearAll()
        
        setupNotificationHandler()
        
        isInitialized = true
        print("✅ OneSignal initialized")
    }

    func requestPermissionAndInitialize() {
        OneSignal.Notifications.requestPermission({ accepted in
            print("🔔 Push permission granted: \(accepted)")
            if accepted {
                self.initializeIfNeeded()
            }
        }, fallbackToSettings: true)
    }
    
    // MARK: - Request permission
    func requestPermission() {
        OneSignal.Notifications.requestPermission({ accepted in
            print("🔔 Push permission granted: \(accepted)")
        }, fallbackToSettings: true)
    }
    
    // MARK: - Get current OneSignal ID
    func getOneSignalID() -> String? {
        return OneSignal.User.onesignalId
    }
    
    // MARK: - Setup notification handling
    private func setupNotificationHandler() {
        OneSignal.Notifications.addForegroundLifecycleListener(self)
        OneSignal.Notifications.addClickListener(self)
    }
}

// MARK: - OneSignal Notification Handlers
extension OneSignalService: OSNotificationLifecycleListener, OSNotificationClickListener {

    // 🔸 Когда пуш приходит в Foreground
    func onWillDisplay(event: OSNotificationWillDisplayEvent) {
        let notification = event.notification
        print("📬 Received notification in foreground: \(notification.notificationId)")
        
        // Дополнительные данные из payload
        if let additionalData = notification.additionalData {
            print("📦 Additional Data: \(additionalData)")
        }
    }

    // 🔸 Когда пользователь кликает по пушу
    func onClick(event: OSNotificationClickEvent) {
        guard
            let additionalData = event.notification.additionalData,
            let urlString = additionalData["url"] as? String,
            let url = URL(string: urlString)
        else {
            print("❌ No URL found in push additional data")
            return
        }

        print("🌐 Push contains URL: \(url)")
        openURLInWebView(url)
    }

    // MARK: - Открыть WebView
    private func openURLInWebView(_ url: URL) {
        DispatchQueue.main.async {
            let webVC = WebviewVC(url: url)
            webVC.modalPresentationStyle = .fullScreen

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }),
               let rootVC = window.rootViewController {

                if let nav = rootVC as? UINavigationController {
                    nav.pushViewController(webVC, animated: true)
                } else if let presented = rootVC.presentedViewController {
                    presented.present(webVC, animated: true)
                } else {
                    rootVC.present(webVC, animated: true)
                }
            } else {
                print("⚠️ Не удалось найти активный rootViewController для показа WebView")
            }
        }
    }
}
