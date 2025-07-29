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

    // Flint Hill, Missouri (for simulator testing)
    private let simulatorLocation = CLLocation(latitude: 38.8628, longitude: -90.8587)

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        start()
    }

    func start() {
        #if targetEnvironment(simulator)
        // Use the test coordinates when running in a simulator
        currentLocation = simulatorLocation
        #else
        manager.startUpdatingLocation()
        #endif
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        #if !targetEnvironment(simulator)
        currentLocation = locations.last
        #endif
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
