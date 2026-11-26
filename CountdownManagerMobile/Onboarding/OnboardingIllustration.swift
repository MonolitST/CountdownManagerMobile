import Lottie
import SwiftUI

struct OnboardingIllustration: View {
    @Environment(\.colorScheme) private var colorScheme
    let page: OnboardingPage
    let isVisible: Bool
    let width: CGFloat

    var body: some View {
        let scale = width / 345
        ZStack(alignment: .topLeading) {
            Image(.onboardingHalo).offset(x: 37, y: 9)
            Image(.onboardingOrbit).offset(x: 24, y: -4)

            switch page {
            case .plans: calendar
            case .reminders: reminders
            case .timer: timer
            }
        }
        .frame(width: 345, height: 290, alignment: .topLeading)
        .scaleEffect(scale, anchor: .topLeading)
        .frame(width: width, height: 290 * scale, alignment: .topLeading)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private var calendar: some View {
        ZStack(alignment: .topLeading) {
            calendarSheet(height: 177, angle: -12).offset(x: 86.6, y: 40.1)
            calendarSheet(height: 190, angle: 10).offset(x: 99.3, y: 48.7)

            VStack(spacing: 0) {
                Text("OCTOBER")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.44)
                    .foregroundStyle(Palette.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(Palette.accent)

                Text(verbatim: "24").font(.custom("PTSerif-Regular", fixedSize: 83))
                    .frame(height: 99)

                Text("SATURDAY")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.99)
                    .foregroundStyle(Palette.secondary)
                    .frame(height: 21)

                Spacer(minLength: 0)
            }
            .frame(width: 168, height: 195)
            .background(Palette.surface)
            .clipShape(.rect(cornerRadius: 17))
            .overlay { RoundedRectangle(cornerRadius: 17).strokeBorder(Palette.outline, lineWidth: 1) }
            .shadow(color: shadowColor, radius: 12, y: 10)
            .offset(x: 88.5, y: 40)

            HStack(spacing: 8) {
                Image(.onboardingCountdownIcon)
                Text("In 2 days").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.accentText)
            }
            .frame(width: 142, height: 44)
            .background(Palette.surface, in: .capsule)
            .overlay { Capsule().strokeBorder(Palette.outline, lineWidth: 1) }
            .shadow(color: shadowColor, radius: 7, y: 6)
            .offset(x: 173, y: 215)

            animation("checklist", localized: true, stillProgress: 0.98, startDelay: .milliseconds(650))
                .frame(width: 174, height: 76)
                .offset(x: 3, y: 206)
        }
    }

    private var reminders: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 12) {
                Image(.onboardingBell)
                    .frame(width: 34, height: 34)
                    .card(Palette.inset, cornerRadius: 11)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Drink water").font(.system(size: 15, weight: .semibold))
                    Text("Every 2 hours").font(.system(size: 13)).foregroundStyle(Palette.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .frame(width: 263, height: 82)
            .background { panel(radius: 17) }
            .offset(x: 33, y: 47)

            animation("reminder", localized: true, stillProgress: 0.98)
                .frame(width: 345, height: 114)
                .offset(y: 135)
        }
    }

    private var timer: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                Text("Focus timer").font(.system(size: 13, weight: .semibold))
                    .frame(height: 18)
                Spacer(minLength: 0)
                Text("Trip to Suzdal").font(.system(size: 13))
                    .frame(height: 18)
            }
            .foregroundStyle(Palette.secondary)
            .padding(.top, 19)
            .padding(.bottom, 30)
            .frame(width: 250, height: 175)
            .background { panel(radius: 20) }
            .offset(x: 47, y: 40)

            Image(.onboardingIslandTimer)
                .frame(width: 20, height: 20)
                .padding(.leading, 14)
                .frame(width: 169, height: 43, alignment: .leading)
                .background(Color(red: 17 / 255, green: 16 / 255, blue: 15 / 255), in: .capsule)
                .shadow(color: shadowColor, radius: 8, y: 6)
                .offset(x: 144, y: 198)

            animation("timer")
                .frame(width: 244, height: 139)
                .offset(x: 53, y: 90)
        }
    }

    private var shadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.28) : Color(red: 0.32, green: 0.22, blue: 0.15).opacity(0.16)
    }

    private func calendarSheet(height: CGFloat, angle: Double) -> some View {
        RoundedRectangle(cornerRadius: 19)
            .fill(Palette.inset)
            .overlay { RoundedRectangle(cornerRadius: 19).strokeBorder(Palette.outline, lineWidth: 1) }
            .frame(width: 163, height: height)
            .rotationEffect(.degrees(angle))
    }

    private func panel(radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Palette.surface)
            .overlay { RoundedRectangle(cornerRadius: radius).strokeBorder(Palette.outline, lineWidth: 1) }
            .shadow(color: shadowColor, radius: 8, y: 6)
    }

    private func animation(
        _ name: String, localized: Bool = false, stillProgress: Double = 0, startDelay: Duration = .zero
    ) -> some View {
        let theme = colorScheme == .dark ? "dark" : "light"
        let localeSuffix = localized ? "-\(AppDate.languageCode)" : ""
        return OnboardingAnimation(
            name: "onboarding-\(name)-\(theme)\(localeSuffix)", isVisible: isVisible,
            stillProgress: stillProgress, startDelay: startDelay
        )
    }
}

private struct OnboardingAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasStarted = false

    let name: String
    let isVisible: Bool
    let stillProgress: Double
    let startDelay: Duration

    var body: some View {
        if let animation = LottieAnimation.named(name) {
            LottieView(animation: animation)
                .resizable()
                .playbackMode(playbackMode)
                .backgroundBehavior(.pauseAndRestore)
                .id(name)
                .onChange(of: isVisible) { _, visible in
                    if !visible { hasStarted = false }
                }
                .task(id: canStart) {
                    guard canStart, !hasStarted else { return }
                    do {
                        // Keep the initial badge visible while the page settles.
                        try await Task.sleep(for: startDelay)
                    } catch {
                        return
                    }
                    if !Task.isCancelled { hasStarted = true }
                }
        }
    }

    private var canStart: Bool {
        startDelay > .zero && isVisible && !reduceMotion && scenePhase == .active
    }

    private var playbackMode: LottiePlaybackMode {
        if reduceMotion { return .paused(at: .progress(stillProgress)) }
        if isVisible && (startDelay == .zero || hasStarted) {
            return .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
        }
        return .paused(at: .progress(0))
    }
}
