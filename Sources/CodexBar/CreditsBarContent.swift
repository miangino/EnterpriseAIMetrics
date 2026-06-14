import CodexBarCore
import SwiftUI

extension UsageMenuCardView.Model {
    struct DailyCreditUsageRow: Equatable {
        let dayText: String
        let creditsText: String
    }

    static func creditsUsageSinceMondayText(input: Input) -> String? {
        guard input.provider == .codex, let dashboard = input.dashboard else { return nil }
        guard let used = dashboard.creditsUsedSinceLastMonday(now: input.now) else { return nil }
        let usedText = UsageFormatter.kiroCreditNumber(used)
        let rawText = String(format: L("%@ credits used since Monday"), usedText)
        return PersonalInfoRedactor.redactEmails(in: rawText, isEnabled: input.hidePersonalInfo)
    }

    static func creditsDailyUsageRows(input: Input) -> [DailyCreditUsageRow]? {
        guard input.provider == .codex, let dashboard = input.dashboard else { return nil }
        let breakdown = dashboard.displayUsageBreakdown(now: input.now)
        guard !breakdown.isEmpty else { return nil }

        let rows = breakdown.prefix(7).compactMap { day -> DailyCreditUsageRow? in
            guard let dayText = Self.dayLabel(for: day.day) else { return nil }
            let creditsText = "\(UsageFormatter.kiroCreditNumber(day.totalCreditsUsed)) credits"
            return DailyCreditUsageRow(dayText: dayText, creditsText: creditsText)
        }
        return rows.isEmpty ? nil : rows
    }

    private static func dayLabel(for day: String) -> String? {
        let formatter = Self.usageDayFormatter
        guard let date = formatter.date(from: day) else { return nil }
        return Self.usageDayDisplayFormatter.string(from: date)
    }

    private static let usageDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let usageDayDisplayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

struct CreditsBarContent: View {
    private static let fullScaleTokens: Double = 1000

    let creditsText: String
    let creditsRemaining: Double?
    let creditsUsageSinceMondayText: String?
    let creditsDailyUsageRows: [UsageMenuCardView.Model.DailyCreditUsageRow]?
    let hintText: String?
    let hintCopyText: String?
    let progressColor: Color
    @Environment(\.menuItemHighlighted) private var isHighlighted

    private var percentLeft: Double? {
        guard let creditsRemaining else { return nil }
        let percent = (creditsRemaining / Self.fullScaleTokens) * 100
        return min(100, max(0, percent))
    }

    private var scaleText: String {
        let scale = UsageFormatter.tokenCountString(Int(Self.fullScaleTokens))
        return "\(scale) \(L("tokens"))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L("Credits"))
                .font(.body)
                .fontWeight(.medium)
            if let percentLeft {
                UsageProgressBar(
                    percent: percentLeft,
                    tint: self.progressColor,
                    accessibilityLabel: L("Credits remaining"))
                HStack(alignment: .firstTextBaseline) {
                    Text(self.creditsText)
                        .font(.caption)
                    Spacer()
                    Text(self.scaleText)
                        .font(.caption)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                }
            } else {
                Text(self.creditsText)
                    .font(.caption)
            }
            if let creditsUsageSinceMondayText, !creditsUsageSinceMondayText.isEmpty {
                Text(creditsUsageSinceMondayText)
                    .font(.footnote)
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let creditsDailyUsageRows, !creditsDailyUsageRows.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Last 7 days"))
                        .font(.footnote)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                    ForEach(Array(creditsDailyUsageRows.enumerated()), id: \.offset) { _, row in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(row.dayText)
                                .font(.footnote)
                            Spacer()
                            Text(row.creditsText)
                                .font(.footnote)
                                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                        }
                    }
                }
            }
            if let hintText, !hintText.isEmpty {
                Text(hintText)
                    .font(.footnote)
                    .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .overlay {
                        ClickToCopyOverlay(copyText: self.hintCopyText ?? hintText)
                    }
            }
        }
    }
}
