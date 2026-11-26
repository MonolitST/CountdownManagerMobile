import Lottie
import SwiftUI

struct LaunchSplash: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onFinished: () -> Void

    private static let animation = LottieAnimation.named("onboarding-splash")

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 4) {
                ZStack {
                    Image(.onboardingSplashOrbit)
                    Image(.onboardingSplashHalo)
                    if !reduceMotion, let animation = Self.animation {
                        LottieView(animation: animation)
                            .resizable()
                            .playing(loopMode: .playOnce)
                            .frame(width: 116, height: 116)
                    } else {
                        Image(.onboardingSplashMark)
                        Image(.onboardingSplashGlyph)
                    }
                }
                .accessibilityHidden(true)
                Text("Countdown Manager")
                    .displayFont(30, relativeTo: .largeTitle)
                    .foregroundStyle(Palette.text)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .position(x: proxy.size.width / 2, y: proxy.size.height * 0.43)
        }
        .background(Palette.background.ignoresSafeArea())
        .task(id: reduceMotion) {
            let duration = reduceMotion ? 0.2 : (Self.animation?.duration ?? 1.02)
            do {
                try await Task.sleep(for: .seconds(duration))
                onFinished()
            } catch {
                // A route that replaces the splash cancels its transition.
            }
        }
    }
}
