//
//  Smart_T_shirtApp.swift
//  Smart T-shirt
//
//  Created by Shayan Hashemi on 4/27/25.
//

import SwiftUI
import UserNotifications // Import UserNotifications

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
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate { // Add UNUserNotificationCenterDelegate

    // Store the ViewModel instance to call its method
    // Ideally, use dependency injection, but for simplicity:
    lazy var ecgViewModel: ECGViewModel = ECGViewModel() 

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set the delegate for notification center
        UNUserNotificationCenter.current().delegate = self
        requestNotificationAuthorization(application: application) // Pass application instance
        return true
    }

    func requestNotificationAuthorization(application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
                return
            }

            if granted {
                print("Notification permission granted.")
                // Attempt to register for remote notifications on the main thread
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("Notification permission denied.")
            }
        }
    }

    // --- Remote Notification Delegate Methods ---

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token data to a string format suitable for sending to the backend
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let tokenString = tokenParts.joined()
        print("Device Token: \(tokenString)")
        
        // TODO: Send this tokenString to your backend
        // Using the ViewModel instance we created
        // Make sure the ViewModel is initialized before this is called (using lazy var helps)
        Task { // Use Task for async operation
             await ecgViewModel.sendDeviceTokenToBackend(token: tokenString)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
        // Handle the error appropriately (e.g., log it, inform the user)
    }

    // --- UNUserNotificationCenter Delegate Methods ---

    // Handle notification when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                willPresent notification: UNNotification, 
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("Received notification while app in foreground: \(notification.request.content.title)")
        // Decide how to present the notification (banner, sound, badge)
        // For this app, showing an alert might be good even in the foreground.
        completionHandler([.banner, .sound, .badge]) 
        
        // You could potentially trigger a data refresh here if needed
        // ecgViewModel.fetchData()
    }

    // Handle user tapping on the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                didReceive response: UNNotificationResponse, 
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        print("User tapped on notification: \(userInfo)")
        
        // Handle the action based on the notification content
        // e.g., navigate to a specific view
        
        completionHandler()
    }
}
