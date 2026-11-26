import SwiftUI

struct FocusTimerView: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chosenMinutes: Int?
    @State private var confirmsReplacing = false
    let plan: Plan

    var body: some View {
        let session = store.data.focus
        let ownSession = session?.planID == plan.id ? session : nil
        let minutes = chosenMinutes ?? ownSession?.minutes ?? store.data.settings.focusMinutes
        ScreenScroll(topPadding: 3) {
            VStack(alignment: .leading, spacing: 20) {
                ScreenNavigation(backLabel: String(localized: "Back to plan"), goBack: { dismiss() })

                VStack(spacing: 8) {
                    Text(String(localized: "Time to get ready"))
                        .displayFont(29)
                        .accessibilityAddTraits(.isHeader)
                    Text(plan.title)
                        .brandFont(14, relativeTo: .subheadline)
                        .foregroundStyle(Palette.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .multilineTextAlignment(.center)

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let seconds = ownSession?.secondsRemaining(at: context.date) ?? minutes * 60
                    let running = ownSession != nil && seconds > 0
                    let finished = ownSession != nil && seconds == 0
                    VStack(spacing: 20) {
                        VStack(spacing: 14) {
                            Text(AppDate.countdown(seconds))
                                .displayFont(68, relativeTo: .largeTitle)
                                .monospacedDigit()
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .contentTransition(.numericText(countsDown: true))
                                .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: seconds)
                                .accessibilityLabel(Duration.seconds(seconds).formatted(
                                    .units(allowed: [.minutes, .seconds], width: .wide).locale(AppDate.locale)
                                ))
                                .accessibilityIdentifier("focus.clock")
                            Text(finished ? String(localized: "Time’s up") : String(localized: "One step at a time."))
                                .brandFont(14, relativeTo: .subheadline)
                                .foregroundStyle(Palette.secondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, minHeight: 170)
                        .card(Palette.inset)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8),
                                                 count: dynamicTypeSize.isAccessibilitySize ? 2 : 4), spacing: 8) {
                            ForEach(Settings.focusDurations, id: \.self) { duration in
                                Button(String(localized: "\(duration) min")) {
                                    if finished { store.clearFocus() }
                                    chosenMinutes = duration
                                }
                                .buttonStyle(OptionButtonStyle(selected: minutes == duration))
                                .accessibilityAddTraits(minutes == duration ? .isSelected : [])
                                .disabled(running)
                                .opacity(running ? 0.55 : 1)
                            }
                        }
                        Button {
                            if running {
                                store.clearFocus()
                            } else if let session, session.planID != plan.id, session.endsAt > .now {
                                confirmsReplacing = true
                            } else {
                                store.startFocus(for: plan, minutes: minutes)
                            }
                        } label: {
                            Label {
                                Text(running ? String(localized: "Stop") : finished ? String(localized: "Restart") : String(localized: "Start"))
                            } icon: {
                                if running { Image(systemName: "stop.fill") } else { DesignIcon(.play) }
                            }
                        }
                        .buttonStyle(BrandButtonStyle())
                        .accessibilityIdentifier("focus.action")
                    }
                }
                Text(String(localized: "Use the timer to get ready.\nYour event stays in your plans."))
                    .brandFont(12, relativeTo: .caption)
                    .foregroundStyle(Palette.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(Palette.text)
        .tint(Palette.accentText)
        .preferredColorScheme(store.data.settings.appearance.colorScheme)
        .sheet(isPresented: $confirmsReplacing) {
            ConceptConfirmationSheet(title: String(localized: "Replace the running timer?"),
                                     actionTitle: String(localized: "Start a new timer")) {
                store.startFocus(for: plan, minutes: minutes)
            }
        }
        .modifier(NotificationIntroduction(onFocusTimer: true))
    }
}
