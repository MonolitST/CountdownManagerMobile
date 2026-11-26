import ActivityKit
import SwiftUI
import WidgetKit

@main
struct FocusActivityWidget: Widget {
    private let islandAccent = Color(red: 0.96, green: 0.61, blue: 0.50)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            FocusLockScreenCard(context: context)
                .widgetURL(context.attributes.timerURL)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    timerIcon.font(.system(size: 19))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    FocusActivityTime(context: context, size: 24, width: 76)
                        .foregroundStyle(islandAccent)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(context.isStale ? LocalizedStringKey("Time’s up") : "Preparation timer")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color(red: 0.76, green: 0.69, blue: 0.60))
                                .environment(\.locale, context.state.locale)
                            Text(context.state.planTitle)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(islandAccent)
                            .accessibilityHidden(true)
                    }
                }
            } compactLeading: {
                timerIcon.font(.system(size: 17))
            } compactTrailing: {
                FocusActivityTime(context: context, size: 13, width: 43)
                    .foregroundStyle(islandAccent)
            } minimal: {
                FocusActivityTime(context: context, size: 11, width: 29)
                    .foregroundStyle(islandAccent)
                    .multilineTextAlignment(.center)
            }
            .widgetURL(context.attributes.timerURL)
            .keylineTint(islandAccent)
        }
    }

    private var timerIcon: some View {
        Image(systemName: "timer")
            .foregroundStyle(islandAccent)
            .accessibilityHidden(true)
    }
}

private struct FocusLockScreenCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let context: ActivityViewContext<FocusActivityAttributes>

    var body: some View {
        let dark = context.state.darkAppearance ?? (colorScheme == .dark)
        let primary = dark ? Color(red: 0.95, green: 0.90, blue: 0.83) : Color(red: 0.19, green: 0.15, blue: 0.13)
        let secondary = dark ? Color(red: 0.76, green: 0.69, blue: 0.60) : Color(red: 0.45, green: 0.36, blue: 0.29)
        let accent = dark ? Color(red: 0.96, green: 0.61, blue: 0.50) : Color(red: 0.70, green: 0.20, blue: 0.12)
        let surface = dark ? Color(red: 0.16, green: 0.13, blue: 0.11) : Color(red: 1, green: 0.98, blue: 0.95)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 11) {
                Image(.activityIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(.rect(cornerRadius: 9))
                    .accessibilityHidden(true)
                Text(context.isStale ? LocalizedStringKey("Time’s up") : "Preparation timer")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(secondary)
                    .environment(\.locale, context.state.locale)
            }
            HStack {
                Text(context.state.planTitle)
                    .font(.headline)
                    .foregroundStyle(primary)
                    .lineLimit(2)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 10)
                FocusActivityTime(context: context, size: 29, width: 89)
                    .foregroundStyle(accent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .activityBackgroundTint(surface.opacity(0.82))
        .activitySystemActionForegroundColor(accent)
    }
}

private struct FocusActivityTime: View {
    let context: ActivityViewContext<FocusActivityAttributes>
    let size: CGFloat
    let width: CGFloat

    var body: some View {
        Group {
            if context.isStale || context.state.startsAt >= context.state.endsAt {
                Text(verbatim: "00:00")
            } else {
                Text(timerInterval: context.state.startsAt...context.state.endsAt, countsDown: true, showsHours: false)
            }
        }
        .font(.system(size: size, weight: .semibold).monospacedDigit())
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .multilineTextAlignment(.trailing)
        .frame(width: width, alignment: .trailing)
    }
}
