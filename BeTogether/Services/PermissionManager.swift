import Foundation
import CoreLocation
import UserNotifications

@MainActor
class PermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = PermissionManager()
    
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation? = nil
    @Published var currentCity: String = ""
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        checkInitialStatus()
    }
    
    private func checkInitialStatus() {
        locationStatus = locationManager.authorizationStatus
        
        // If already authorized, request location immediately
        if locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
        
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
    
    func requestCurrentLocation() {
        guard locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways else { return }
        locationManager.requestLocation()
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.locationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.locationManager.requestLocation()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            self.reverseGeocode(location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor in
                if let city = placemarks?.first?.locality {
                    self?.currentCity = city
                } else if let area = placemarks?.first?.administrativeArea {
                    self?.currentCity = area
                } else {
                    self?.currentCity = "Unknown"
                }
            }
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
