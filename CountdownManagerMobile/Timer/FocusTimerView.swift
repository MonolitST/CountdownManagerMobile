import SwiftUI

struct FocusTimerView: View {
    @Environment(PlannerViewModel.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chosenMinutes: Int?
    @State private var confirmsReplacing = false
    let plan: Plan
    var tablet = false

    var body: some View {
        Group {
            if tablet {
                ViewThatFits(in: .vertical) {
                    content
                    ScrollView { content }
                }
                .frame(idealWidth: 420, maxWidth: 420)
            } else {
                ScreenScroll(topPadding: 3) {
                    VStack(alignment: .leading, spacing: 20) {
                        ScreenNavigation(backLabel: String(localized: "Back to plan"), goBack: { dismiss() })
                        content.padding(.top, 24)
                        Text(String(localized: "Use the timer to get ready.\nYour event stays in your plans."))
                            .brandFont(12, relativeTo: .caption)
                            .foregroundStyle(Palette.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .frame(maxWidth: .infinity)
                    }
                }
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

    private var ownSession: FocusSession? {
        store.data.focus.flatMap { $0.planID == plan.id ? $0 : nil }
    }

    private var minutes: Int {
        chosenMinutes ?? ownSession?.minutes ?? store.data.settings.focusMinutes
    }

    private var content: some View {
        VStack(spacing: tablet ? 12 : 20) {
            VStack(spacing: 8) {
                Text("Time to get ready").displayFont(29)
                    .accessibilityAddTraits(.isHeader)
                Text(plan.title)
                    .brandFont(14, relativeTo: .subheadline)
                    .foregroundStyle(Palette.secondary)
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)

            TimelineView(.periodic(from: .now, by: 1)) { context in
                let seconds = ownSession?.secondsRemaining(at: context.date) ?? minutes * 60
                let running = ownSession?.isRunning(at: context.date) ?? false
                let paused = ownSession?.pausedSeconds != nil
                let finished = ownSession != nil && seconds == 0
                VStack(spacing: tablet ? 14 : 20) {
                    clock(seconds, finished: finished)
                    if !tablet || (!running && !paused) {
                        presets(active: running || paused, finished: finished)
                    }
                    actions(running: running, paused: paused, finished: finished)
                }
            }
        }
        .padding(.horizontal, tablet ? 22 : 0)
        .padding(.vertical, tablet ? 20 : 0)
    }

    private func clock(_ seconds: Int, finished: Bool) -> some View {
        VStack(spacing: 14) {
            Text(AppDate.countdown(seconds))
                .displayFont(tablet ? 76 : 68, relativeTo: .largeTitle)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText(countsDown: true))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: seconds)
                .accessibilityLabel(Duration.seconds(seconds).formatted(
                    .units(allowed: [.minutes, .seconds], width: .wide).locale(AppDate.locale)
                ))
                .accessibilityIdentifier("focus.clock")
            if finished || !tablet {
                Text(finished ? String(localized: "Time’s up") : String(localized: "One step at a time."))
                    .brandFont(14, relativeTo: .subheadline)
                    .foregroundStyle(Palette.secondary)
            }
        }
        .padding(tablet ? 0 : 16)
        .frame(maxWidth: .infinity, minHeight: tablet ? 97 : 170)
        .card(tablet ? .clear : Palette.inset)
    }

    private func presets(active: Bool, finished: Bool) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8),
                                count: dynamicTypeSize.isAccessibilitySize ? 2 : 4), spacing: 8) {
            ForEach(Settings.focusDurations, id: \.self) { duration in
                Button(String(localized: "\(duration) min")) {
                    if finished { store.clearFocus() }
                    chosenMinutes = duration
                }
                .buttonStyle(OptionButtonStyle(selected: minutes == duration, showsOutlineWhenUnselected: !tablet))
                .background(tablet ? Palette.inset : .clear, in: .rect(cornerRadius: 11))
                .accessibilityAddTraits(minutes == duration ? .isSelected : [])
                .disabled(active)
                .opacity(active ? 0.55 : 1)
            }
        }
    }

    private func actions(running: Bool, paused: Bool, finished: Bool) -> some View {
        HStack(spacing: 12) {
            Button {
                if paused {
                    store.resumeFocus(for: plan.id)
                } else if running {
                    if tablet { store.pauseFocus(for: plan.id) } else { store.clearFocus() }
                } else if let session = store.data.focus, session.planID != plan.id, session.secondsRemaining(at: .now) > 0 {
                    confirmsReplacing = true
                } else {
                    store.startFocus(for: plan, minutes: minutes)
                }
            } label: {
                Label {
                    Text(actionTitle(running: running, paused: paused, finished: finished))
                } icon: {
                    if !running && !paused { DesignIcon(.play) }
                    if running && !tablet { Image(systemName: "stop.fill") }
                }
                .padding(.horizontal, tablet ? 10 : 0)
            }
            .buttonStyle(BrandButtonStyle(compact: tablet))
            .frame(maxWidth: tablet ? 126 : .infinity)
            .accessibilityIdentifier("focus.action")
            if tablet {
                Button(running || paused ? String(localized: "Finish") : String(localized: "Cancel")) {
                    if running || paused { store.clearFocus() }
                    dismiss()
                }
                .buttonStyle(.plain)
                .brandFont(14, weight: .semibold, relativeTo: .subheadline)
                .foregroundStyle(Palette.accentText)
                .padding(.horizontal, 13)
                .frame(minHeight: 44)
                .card(running || paused ? Palette.inset : .clear, cornerRadius: 11)
            }
        }
    }

    private func actionTitle(running: Bool, paused: Bool, finished: Bool) -> String {
        if paused { return String(localized: "Resume") }
        if running { return tablet ? String(localized: "Pause") : String(localized: "Stop") }
        return finished ? String(localized: "Restart") : String(localized: "Start")
    }
}
