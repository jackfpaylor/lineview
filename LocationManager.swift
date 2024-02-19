import CoreLocation
import SwiftUI

protocol LocationManagerDelegate: AnyObject {
    func didEnterBarRegion(_ barId: String)
    // Add any other location-related delegate methods you need
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    weak var delegate: LocationManagerDelegate?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
    }
    
    func requestAlwaysAuthorization() {
        // For iOS 14 and later, use the instance property `authorizationStatus`.
        let currentStatus = locationManager.authorizationStatus
        
        switch currentStatus {
            case .notDetermined:
                locationManager.requestAlwaysAuthorization()
            case .authorizedWhenInUse:
                // Request to upgrade the permission to always from when in use
                locationManager.requestAlwaysAuthorization()
            default:
                // Handle other cases if needed
                break
        }
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func setupGeofences(bars: [Bar]) {
        // Clear any existing geofences
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        // Set up new geofences
        for bar in bars {
            let center = CLLocationCoordinate2D(latitude: bar.latitude, longitude: bar.longitude)
            let geofenceRegion = CLCircularRegion(center: center, radius: bar.radius, identifier: bar.id)
            geofenceRegion.notifyOnEntry = true
            geofenceRegion.notifyOnExit = false
            locationManager.startMonitoring(for: geofenceRegion)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined, .restricted, .denied:
            // Handle as appropriate
            break
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        @unknown default:
            fatalError("Unhandled authorization status")
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            delegate?.didEnterBarRegion(region.identifier)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failure to get location")
    }
}
