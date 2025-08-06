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

    private func createDateCustomTimeZone(
        day: Int, month: Int, year: Int,
        hour: Int, minute: Int, seconds: Int,
        nanosecond: Int = 0,
        timeZone: TimeZone
    ) -> Date {
        var calendar: Calendar = .init(identifier: .gregorian)
        calendar.timeZone = timeZone
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = seconds
        dateComponents.nanosecond = nanosecond

        return calendar.date(from: dateComponents) ?? Date()
    }

    private func getNowInTimeZone() -> Date {
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: timeZone, from: now)

        return createDateCustomTimeZone(
            day: components.day ?? 1,
            month: components.month ?? 1,
            year: components.year ?? 2023,
            hour: components.hour ?? 12,
            minute: components.minute ?? 0,
            seconds: components.second ?? 0,
            timeZone: timeZone
        )
    }

    func getCurrentSun() -> Sun {
        let date = getNowInTimeZone()
        var sun = Sun(location: location, timeZone: timeZone)
        sun.setDate(date)
        return sun
    }

    func getCurrentMoon() -> Moon {
        let moon = Moon(location: location, timeZone: timeZone)
        let now = Date()
        moon.setDate(now)
        return moon
    }
}
