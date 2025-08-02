//
//  SunAndMoonWidgetExtension.swift
//  SunAndMoonWidgetExtension
//
//  Created by Heather Gulledge on 8/2/25.
//

import WidgetKit
import SwiftUI
import CoreLocation
import SunKit
import MoonKit

// MARK: - Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        makeEntry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let currentDate = Date()
        var entries: [SimpleEntry] = []

        for hourOffset in 0..<5 {
            let date = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            entries.append(makeEntry(for: date))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func makeEntry(for date: Date) -> SimpleEntry {
        #if targetEnvironment(simulator)
        let location = CLLocation(latitude: 38.8628, longitude: -90.8587) // Flint Hill fallback for simulator
        #else
        let locationManager = CLLocationManager()
        let location = locationManager.location ?? CLLocation(latitude: 38.8628, longitude: -90.8587) // fallback only if location unavailable
        #endif

        let astronomy = AstronomyService(location: location)
        let sun = astronomy.getCurrentSun()
        let moon = astronomy.getCurrentMoon()

        return SimpleEntry(
            date: date,
            sunrise: sun.sunrise,
            sunset: sun.sunset,
            moonPhase: String(describing: moon.currentMoonPhase)
        )
    }
}

// MARK: - Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let sunrise: Date?
    let sunset: Date?
    let moonPhase: String
}

// MARK: - Widget View

struct SunAndMoonWidgetExtensionEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let sunrise = entry.sunrise, let sunset = entry.sunset {
                if entry.date >= sunrise && entry.date <= sunset {
                    let duration = sunset.timeIntervalSince(sunrise)
                    let hours = Int(duration) / 3600
                    let minutes = (Int(duration) % 3600) / 60
                    Text("☀️ Daylight")
                    Text("\(hours)h \(minutes)m")
                } else {
                    Text("🌙 \(entry.moonPhase)")
                }
            } else {
                Text("Sun & Moon")
            }
        }
        .font(.footnote)
    }
}

// MARK: - Widget Main

@main
struct SunAndMoonWidgetExtension: Widget {
    let kind: String = "SunAndMoonWidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SunAndMoonWidgetExtensionEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Sun & Moon")
        .description("Shows daylight duration or moon phase")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
