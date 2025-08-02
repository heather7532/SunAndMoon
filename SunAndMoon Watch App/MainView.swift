//
//  MainView.swift
//  SunAndMoon Watch App
//
//  Created by Heather Gulledge on 7/28/25.
//

import SwiftUI
import CoreLocation
import SunKit
import MoonKit



struct MainView: View {
    @StateObject private var locationService = LocationService()
    @State private var heading: Double = 0.0
    @State private var sun: Sun?
    @State private var moon: Moon?

    private let timeZone = TimeZone.current
    private var astronomyService: AstronomyService? {
        guard let location = locationService.currentLocation else { return nil }
        return AstronomyService(location: location, timeZone: timeZone)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Sun & Moon Tracker")
                    .font(.headline)
                    .padding(.bottom, 4)

                if let sun = sun, let moon = moon {
                    // Daylight section
                    SectionHeader(title: "Daylight")
                    DataRow(label: "Nautical Dawn", value: sun.nauticalDawn.formattedTime())
                    DataRow(label: "Civil Dawn", value: sun.civilDawn.formattedTime())
                    DataRow(label: "Sunrise", value: sun.sunrise.formattedTime())
                    DataRow(label: "Sunset", value: sun.sunset.formattedTime())
                    DataRow(label: "Civil Dusk", value: sun.civilDusk.formattedTime())
                    DataRow(label: "Nautical Dusk", value: sun.nauticalDusk.formattedTime())
                    DataRow(label: "Day Duration", value: sun.totalDayLightTime.toHourMinuteString())
                    DataRow(label: "Night Duration", value: sun.totalNightTime.toHourMinuteString())
                    DataRow(
                        label: "Sun Azimuth",
                        value: formattedAngle(sun.azimuth.degrees),
                        highlight: isHeadingAligned(to: sun.azimuth.degrees)
                    )
                    DataRow(label: "Sun Altitude", value: formattedAngle(sun.altitude.degrees))

                    Divider().padding(.vertical, 6)

                    // Moon section
                    SectionHeader(title: "Moon")
                    DataRow(label: "Moonrise", value: moon.moonRise?.formattedTime() ?? "--:--")
                    DataRow(label: "Moonset", value: moon.moonSet?.formattedTime() ?? "--:--")
                    DataRow(
                        label: "Moon Azimuth",
                        value: formattedAngle(moon.azimuth),
                        highlight: isHeadingAligned(to: moon.azimuth)
                    )
                    DataRow(label: "Moon Altitude", value: formattedAngle(moon.altitude))
                    DataRow(label: "Next New Moon", value: formattedDate(from: moon.nextNewMoon))
                    DataRow(label: "Next Full Moon", value: formattedDate(from: moon.nextFullMoon))
                    ValueRow(value: String(describing: moon.currentMoonPhase))
                } else {
                    Text("Fetching location and data...")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                }
            }
            .padding()
        }
        .onAppear {
            locationService.fetchLocationIfAuthorized()
            locationService.startHeadingUpdates { newHeading in
                self.heading = newHeading
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                refreshAstronomyData()
            }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            refreshAstronomyData()
        }
    }

    // MARK: - Helpers
    


    
    private func formattedDate(from seconds: Int?) -> String {
        guard let seconds = seconds else { return "--:--" }
        let date = Date().addingTimeInterval(TimeInterval(seconds))
        return date.formattedTime()
    }
    
    private func refreshAstronomyData() {
        guard let service = astronomyService else { return }
        sun = service.getCurrentSun()
        moon = service.getCurrentMoon()
    }

    private func formattedAngle(_ angle: Double?) -> String {
        guard let angle = angle else { return "--°" }
        return "\(Int(angle.rounded()))°"
    }

    private func isHeadingAligned(to azimuth: Double?) -> Bool {
        guard let azimuth = azimuth else { return false }
        return abs(heading - azimuth).truncatingRemainder(dividingBy: 360) <= 3
    }
}

// MARK: - Helper Extensions
extension Date {
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

extension Int {
    func toHourMinuteString() -> String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

extension Date {
    func formattedDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium   // e.g., "Aug 3, 2025"
        formatter.timeStyle = .short    // e.g., "11:04 PM"
        return formatter.string(from: self)
    }
}


// MARK: - Subviews
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.subheadline)
            .bold()
            .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.6)) // Alpenlogic blue
            .padding(.vertical, 3)
            .padding(.horizontal, 6)
            .background(Color.white)
            .cornerRadius(6)
            .padding(.top, 4)
    }
}

struct DataRow: View {
    let label: String
    let value: String
    var highlight: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .frame(alignment: .trailing)
                .monospacedDigit()
                .foregroundColor(highlight ? .green : .primary)
        }
        .font(.footnote)
    }
}

struct ValueRow: View {
    let value: String
    var body: some View {
        HStack {
            Text(value)
                .monospacedDigit()
        }
        .font(.footnote)
    }
}

// MARK: - Preview
#Preview {
    MainView()
}


