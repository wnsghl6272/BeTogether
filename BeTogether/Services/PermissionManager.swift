import Foundation
import CoreLocation
import UserNotifications

@MainActor
class PermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = PermissionManager()
    
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    
    override private init() {
        super.init()
        locationManager.delegate = self
        checkInitialStatus()
    }
    
    private func checkInitialStatus() {
        locationStatus = locationManager.authorizationStatus
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Location
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.locationStatus = status
        }
    }
    
    // MARK: - Notifications
    func requestNotificationPermission() async {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            self.notificationStatus = settings.authorizationStatus
            print("Notification permission granted: \(granted)")
        } catch {
            print("Error requesting notification permissions: \(error)")
        }
    }
}
