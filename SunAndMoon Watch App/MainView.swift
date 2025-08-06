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

private func symbolNameForPhase(_ phase: MoonPhase) -> String {
    let raw = phase.rawValue

    // Convert camelCase to dot.case
    let dotted = raw
        .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1.$2", options: .regularExpression)
        .replacingOccurrences(of: " ", with: ".")
        .lowercased()

    let symbolName = "moonphase.\(dotted)"
    print("Resolved SF Symbol for phase '\(raw)': \(symbolName)")
    return symbolName
}

struct MainView: View {
    @StateObject private var locationService = LocationService()
    @State private var heading: Double = 0.0
    @State private var sun: Sun?
    @State private var moon: Moon?
    @State private var navSelection: MoonNavigation?
    @State private var moonImage: CGImage?

    private let timeZone = TimeZone.current
    private var astronomyService: AstronomyService? {
        guard let location = locationService.currentLocation else { return nil }
        return AstronomyService(location: location, timeZone: timeZone)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    if let sun = sun, let moon = moon {
                        SectionHeader(title: "Sun")
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

                        SectionHeader(title: "Moon")
                        DataRow(label: "Moonrise", value: moon.moonRise?.formattedTime() ?? "--:--")
                        DataRow(label: "Moonset", value: moon.moonSet?.formattedTime() ?? "--:--")
                        DataRow(
                            label: "Moon Azimuth",
                            value: formattedAngle(moon.azimuth),
                            highlight: isHeadingAligned(to: moon.azimuth)
                        )
                        DataRow(label: "Moon Altitude", value: formattedAngle(moon.altitude))
                        DataRow(label: "New Moon", value: formattedDate(from: formattedDateFromNow(days: moon.nextNewMoon)))
                        DataRow(label: "Full Moon", value: formattedDate(from: formattedDateFromNow(days: moon.nextFullMoon)))
                        MoonPhaseRow(
                            phaseName: moon.currentMoonPhase.rawValue,
                            phasePercent: CGFloat(moon.moonPercentage/100),
                            moonAge: CGFloat(moon.ageOfTheMoonInDays),
                            latitude: locationService.currentLocation?.coordinate.latitude ?? 0.0,
                            moonImage: moonImage,
                        )
                    } else {
                        Text("Fetching location and data...")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                    }
                }
                .padding()
            }
            .navigationDestination(for: MoonNavigation.self) { selection in
                switch selection {
                case .slider(let latitude, let moonAge):
                    if let moonImage = moonImage {
                        MoonPhaseSliderView(
                            latitude: latitude,
                            fullMoonCG: moonImage,
                            initialMoonAge: moonAge
                        )
                    } else {
                        Text("Moon image not available")
                    }
                }
            }
        }
        .onAppear {
            locationService.fetchLocationIfAuthorized()
            locationService.startHeadingUpdates { newHeading in
                self.heading = newHeading
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                refreshAstronomyData()
            }

            if let image = UIImage(named: "fullmoon")?.cgImage {
                self.moonImage = image
            }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            refreshAstronomyData()
        }
    }
    
    // MARK: - Helpers
    
    struct ImageRow: View {
        let label: String
        let imageName: String
        
        var body: some View {
            HStack {
                Text(label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .accessibilityLabel(Text(label))
            }
            .font(.footnote)
        }
    }
    
    private func formatPhaseName(_ rawValue: String) -> String {
        rawValue
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .capitalized
    }
    
    private func imageNameForPhase(_ phase: String) -> String {
        phase
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
    }
    
    private func formattedDate(from date: Date?) -> String {
        guard let date = date else { return "--" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let full = formatter.string(from: date)
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let dateYear = calendar.component(.year, from: date)
        
        if currentYear == dateYear {
            // Strip the year from the formatted date
            return full.replacingOccurrences(of: String(currentYear), with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: ",./-"))
        } else {
            return full
        }
    }
    
    private func formattedDateFromNow(days: Int?) -> Date? {
        guard let days = days else { return nil }
        return Calendar.current.date(byAdding: .day, value: days, to: Date())
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
        return abs(heading - azimuth).truncatingRemainder(dividingBy: 360) <= 5
    }
    

    enum MoonNavigation: Hashable {
        case slider(latitude: CLLocationDegrees, moonAge: CGFloat)
    }

    struct MoonPhaseRow: View {
        let phaseName: String
        let phasePercent: CGFloat
        let moonAge: CGFloat
        let latitude: CLLocationDegrees
        let moonImage: CGImage?

        var body: some View {
            HStack {
                Text(phaseName)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let moonImage = moonImage {
                    NavigationLink(value: MoonNavigation.slider(latitude: latitude, moonAge: moonAge)) {
                        MoonRendererWatch(
                            latitude: latitude,
                            phasePercent: phasePercent,
                            moonAge: moonAge,
                            fullMoonCG: moonImage
                        )
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .accessibilityLabel(Text(phaseName))
                    }
                    .buttonStyle(.plain)
                } else {
                    ProgressView()
                        .frame(width: 24, height: 24)
                }
            }
            .font(.footnote)
        }
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
