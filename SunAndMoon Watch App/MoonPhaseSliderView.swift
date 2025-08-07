import SwiftUI
import CoreLocation

struct MoonPhaseSliderView: View {
    let latitude: CLLocationDegrees
    let fullMoonCG: CGImage
    let initialMoonAge: CGFloat
    let fullMoonShadowCG: CGImage

    @State private var simulatedAge: Double = 0.0

    private let synodicMonth: Double = 29.53

    var body: some View {
        VStack(spacing: 8) {
            // Derived date
            Text(simulatedDate.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)

            MoonRendererWatch(
                latitude: latitude,
                phasePercent: phasePercent(for: simulatedAge),
                moonAge: simulatedAge,
                fullMoonCG: fullMoonCG,
                shadowCG: fullMoonShadowCG,
            )
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 80, height: 80)
            .clipped()
            .animation(.easeInOut(duration: 0.3), value: simulatedAge)  // 👈 Animated redraw

            Slider(value: $simulatedAge, in: 0...synodicMonth, step: 1)
                .padding(.horizontal)
        }
        .onAppear {
            simulatedAge = Double(initialMoonAge)
        }
        .padding()
    }

    private var simulatedDate: Date {
        let deltaDays = simulatedAge - Double(initialMoonAge)
        return Calendar.current.date(byAdding: .day, value: Int(deltaDays.rounded()), to: Date()) ?? Date()
    }

    private func phasePercent(for age: Double) -> CGFloat {
        let percent = 0.5 * (1 - cos((age / synodicMonth) * 2 * .pi))
        return CGFloat(percent)
    }
}
