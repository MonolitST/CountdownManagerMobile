import SwiftUI

struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var page = OnboardingPage.plans

    let onCreatePlan: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(OnboardingPage.allCases) { slide in
                    OnboardingSlide(page: slide, isVisible: page == slide)
                        .tag(slide)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            pagination

            VStack(spacing: verticalSizeClass == .compact ? 2 : 14) {
                Button(page.next == nil ? String(localized: "Create your first plan") : String(localized: "Next")) {
                    if let next = page.next {
                        go(to: next)
                    } else {
                        onCreatePlan()
                    }
                }
                .buttonStyle(BrandButtonStyle(minimumHeight: 50))
                .accessibilityIdentifier("onboarding.primary")

                Button("Not now", action: onSkip)
                    .buttonStyle(.plain)
                    .brandFont(14, weight: .semibold, relativeTo: .subheadline)
                    .foregroundStyle(Palette.secondary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(.rect)
                    .accessibilityIdentifier("onboarding.skip")
            }
            .frame(maxWidth: 345)
            .padding(.horizontal, 24)
            .padding(.top, verticalSizeClass == .compact ? 0 : 32)
        }
        .padding(.bottom, 9)
        .foregroundStyle(Palette.text)
        .background(Palette.background.ignoresSafeArea())
    }

    private var pagination: some View {
        HStack(spacing: 0) {
            ForEach(OnboardingPage.allCases) { slide in
                let isSelected = page == slide
                Button { go(to: slide) } label: {
                    Capsule()
                        .fill(isSelected ? Palette.accent : Palette.secondary.opacity(0.33))
                        .frame(width: isSelected ? 18 : 8, height: 8)
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Page \(slide.rawValue + 1) of \(OnboardingPage.allCases.count)"))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("onboarding.page.\(slide.rawValue + 1)")
            }
        }
    }

    private func go(to destination: OnboardingPage) {
        withAnimation(reduceMotion ? nil : .easeInOut) { page = destination }
    }
}

private struct OnboardingSlide: View {
    @Environment(\.dynamicTypeSize) private var dynamicType
    let page: OnboardingPage
    let isVisible: Bool

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let width = proxy.size.width
            let illustrationWidth = min(345, max(0, width - 48), height * 0.75)
            let useDesignLineBreaks = width >= 375 && dynamicType <= .large
            let title = String(localized: page.title)
            let message = String(localized: page.message)

            ScrollView {
                VStack(spacing: 0) {
                    OnboardingIllustration(page: page, isVisible: isVisible, width: illustrationWidth)
                        .padding(.bottom, 25)

                    VStack(spacing: -6) {
                        if useDesignLineBreaks {
                            ForEach(title.split(separator: "\n"), id: \.self) { line in
                                Text(verbatim: String(line))
                            }
                        } else {
                            Text(verbatim: title.replacingOccurrences(of: "\n", with: " "))
                        }
                    }
                        .displayFont(36, relativeTo: .largeTitle)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(verbatim: title))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("onboarding.title.\(page.rawValue + 1)")

                    Text(verbatim: useDesignLineBreaks ? message : message.replacingOccurrences(of: "\n", with: " "))
                        .brandFont(16)
                        .lineSpacing(4)
                        .foregroundStyle(Palette.secondary)
                        .frame(maxWidth: 306)
                        .padding(.top, 19)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, height >= 520 ? 44 : 12)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
    }
}
