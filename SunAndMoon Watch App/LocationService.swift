//
//  LocationService.swift
//  SunAndMoon Watch App
//
//  Created by Heather Gulledge on 7/28/25.
//

import Foundation
import CoreLocation

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var currentHeading: Double?

    private var headingCallback: ((Double) -> Void)?

    // Flint Hill, Missouri — for simulator testing
    private let simulatorLocation = CLLocation(latitude: 38.8628, longitude: -90.8587)

    override init() {
        super.init()
        manager.delegate = self
    }

    // Call from .onAppear
    func fetchLocationIfAuthorized() {
        #if targetEnvironment(simulator)
        currentLocation = simulatorLocation
        #else
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
            manager.startUpdatingHeading()
        default:
            print("Location access denied or restricted")
        }
        #endif
    }

    func startHeadingUpdates(_ callback: @escaping (Double) -> Void) {
        headingCallback = callback
        #if targetEnvironment(simulator)
        callback(90.0) // East for simulator
        #else
        manager.startUpdatingHeading()
        #endif
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        fetchLocationIfAuthorized()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        #if !targetEnvironment(simulator)
        currentLocation = locations.last
        #endif
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading.trueHeading
        headingCallback?(newHeading.trueHeading)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
}
