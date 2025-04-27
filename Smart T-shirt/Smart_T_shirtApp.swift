//
//  Smart_T_shirtApp.swift
//  Smart T-shirt
//
//  Created by Shayan Hashemi on 4/27/25.
//

import SwiftUI

@main
struct Smart_T_shirtApp: App {
    // Add AppDelegate adapter to handle app lifecycle events like requesting permissions
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Create AppDelegate to handle requesting notification permissions
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        requestNotificationAuthorization()
        return true
    }

    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
                // Handle the error here.
            }

            if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
                // Handle the case where permission is denied
            }
        }
    }
}
