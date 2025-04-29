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
                print("Erreur lors de la demande d'autorisation de notification: \(error.localizedDescription)")
                return
            }

            if granted {
                print("Autorisation de notification accordée.")
                // Request for local notifications only - no remote needed
                self.setupNotificationCategories()
            } else {
                print("Autorisation de notification refusée.")
            }
        }
    }
    
    // Setup notification categories and actions
    private func setupNotificationCategories() {
        // Define action for calling emergency
        let callAction = UNNotificationAction(
            identifier: "CALL_ACTION",
            title: "Appeler les urgences",
            options: .foreground
        )
        
        // Define action for dismissing
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Ignorer",
            options: .destructive
        )
        
        // Create category with actions
        let abnormalCategory = UNNotificationCategory(
            identifier: "ECG_ABNORMAL",
            actions: [callAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Register the category
        UNUserNotificationCenter.current().setNotificationCategories([abnormalCategory])
    }

    // --- Remote Notification Delegate Methods ---

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // We're not actually using remote notifications, but keeping this method stub
        // in case you need it in the future
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let tokenString = tokenParts.joined()
        print("Token de l'appareil: \(tokenString)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // This error is expected since we don't have proper entitlements for remote notifications
        // Just log it, but no need to show to user
        print("Échec de l'enregistrement pour les notifications à distance: \(error.localizedDescription)")
    }

    // --- UNUserNotificationCenter Delegate Methods ---

    // Handle notification when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                willPresent notification: UNNotification, 
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("Notification reçue avec l'application au premier plan: \(notification.request.content.title)")
        
        // On iOS 14 and later, we can show notification banner even in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }

    // Handle user tapping on the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                didReceive response: UNNotificationResponse, 
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // Handle action based on identifier
        switch response.actionIdentifier {
        case "CALL_ACTION":
            if let url = URL(string: "tel://112") {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself
            print("L'utilisateur a appuyé sur la notification")
            // Could navigate to a specific view here if needed
        default:
            break
        }
        
        completionHandler()
    }
}
