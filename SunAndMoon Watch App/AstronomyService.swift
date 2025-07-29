//
//  AstronomyService.swift
//  SunAndMoon Watch App
//
//  Created by Heather Gulledge on 7/28/25.
//

import Foundation
import CoreLocation
import SunKit
import MoonKit

class AstronomyService {
    private let location: CLLocation
    private let timeZone: TimeZone

    init(location: CLLocation, timeZone: TimeZone = .current) {
        self.location = location
        self.timeZone = timeZone
    }

    // MARK: - Sun
    func getCurrentSun() -> Sun {
        // SunKit calculates current sun data based on date and location
        return Sun(location: location, timeZone: timeZone)
    }

    // MARK: - Moon
    func getCurrentMoon() -> Moon {
        // MoonKit calculates current moon data based on date and location
        return Moon(location: location, timeZone: timeZone)
    }
}
