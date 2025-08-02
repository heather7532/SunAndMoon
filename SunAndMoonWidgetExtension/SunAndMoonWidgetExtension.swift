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
        let location = CLLocation(latitude: 38.8628, longitude: -90.8587) // Flint Hill fallback
        #else
        let locationManager = CLLocationManager()
        let location = locationManager.location ?? CLLocation(latitude: 38.8628, longitude: -90.8587)
        #endif

        let astronomy = AstronomyService(location: location)
        let sun = astronomy.getCurrentSun()
        let moon = astronomy.getCurrentMoon()

        return SimpleEntry(
            date: date,
            sunrise: sun.sunrise,
            sunset: sun.sunset,
            civilDawn: sun.civilDawn,
            civilDusk: sun.civilDusk,
            sunAltitude: sun.altitude.degrees ?? -90,
            moonPhase: String(describing: moon.currentMoonPhase)
        )
    }
}

// MARK: - Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let sunrise: Date?
    let sunset: Date?
    let civilDawn: Date?
    let civilDusk: Date?
    let sunAltitude: Double
    let moonPhase: String
}

// MARK: - Widget View

struct SunAndMoonWidgetExtensionEntryView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            Image(systemName: "sun.and.moon.fill")
                .resizable()
                .scaledToFit()
                .padding(10)
                .foregroundStyle(.white)

        case .accessoryInline, .accessoryRectangular:
            if let timeInfo = computeTimeInfo(entry: entry) {
                let minutes = Int(timeInfo.secondsRemaining / 60)
                let hours = minutes / 60
                let mins = minutes % 60
                Text("\(hours)h \(mins)m")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(timeInfo.color)
            } else {
                Text("--")
            }

        default:
            Text("Sun & Moon")
        }
    }

    struct TimeInfo {
        let secondsRemaining: TimeInterval
        let color: Color
    }

    private func computeTimeInfo(entry: SimpleEntry) -> TimeInfo? {
        guard let civilDawn = entry.civilDawn, let civilDusk = entry.civilDusk else { return nil }
        let now = entry.date

        if now >= civilDawn && now < civilDusk {
            // Daytime: until dusk
            let seconds = civilDusk.timeIntervalSince(now)
            return TimeInfo(secondsRemaining: seconds, color: colorForSunAltitude(entry.sunAltitude))
        } else {
            // Nighttime: until next dawn
            let targetDawn: Date = now < civilDawn
                ? civilDawn
                : Calendar.current.date(byAdding: .day, value: 1, to: civilDawn) ?? civilDawn.addingTimeInterval(86400)

            let seconds = targetDawn.timeIntervalSince(now)
            return TimeInfo(secondsRemaining: seconds, color: .white)
        }
    }

    private func colorForSunAltitude(_ altitude: Double) -> Color {
        switch altitude {
        case let a where a >= 10:
            return .yellow
        case 0..<10:
            return .orange
        case -6..<0:
            return .pink
        case -12..<(-6):
            return .purple
        case -18..<(-12):
            return .blue
        default:
            return .white
        }
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
        .description("Shows daylight or nighttime countdown")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
