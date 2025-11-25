//
//  AppDelegate.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 10.11.2025.
//

import UIKit
import Firebase
import AppsFlyerLib

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var restrictRotation: UIInterfaceOrientationMask = .all

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // FireBase
        //FirebaseApp.configure()
        
        // AppsFlyer Init
        AppsFlyerLib.shared().appsFlyerDevKey = "kVjTyqsKBgM6mUVpSzaN4j"
        AppsFlyerLib.shared().appleAppID = "6755160410"
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().isDebug = true
        AppsFlyerLib.shared().disableAdvertisingIdentifier = true
        AppsFlyerLib.shared().start()

        //OneSignal
        OneSignalService.shared.requestPermissionAndInitialize()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

