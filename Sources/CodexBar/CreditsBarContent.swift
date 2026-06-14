import CodexBarCore
import SwiftUI

extension UsageMenuCardView.Model {
    struct DailyCreditUsageRow: Equatable {
        let dayText: String
        let creditsText: String
        let isEstimated: Bool
    }

    static func creditsDailyUsageHeaderText(input: Input) -> String? {
        guard input.provider == .codex, input.dashboard != nil else { return nil }
        return L("Monday to date")
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
        let calendar = Calendar.current
        let startOfWeek = Self.startOfWeek(containing: input.now, calendar: calendar)
        let formatter = Self.usageDayFormatter
        let startKey = formatter.string(from: startOfWeek)
        let endKey = formatter.string(from: input.now)
        let breakdown = dashboard.displayUsageBreakdown(now: input.now)
            .filter { $0.day >= startKey && $0.day <= endKey }
        guard !breakdown.isEmpty else { return nil }

        let todayKey = formatter.string(from: input.now)
        let rows = breakdown.compactMap { day -> DailyCreditUsageRow? in
            guard let dayText = Self.dayLabel(for: day.day) else { return nil }
            let estimatedCreditsText = Self.estimatedCreditsText(
                input: input,
                breakdown: breakdown,
                todayKey: todayKey)
            let isEstimated = day.day == todayKey && estimatedCreditsText != nil
            let creditsText =
                if day.day == todayKey, day.totalCreditsUsed == 0, day.services.isEmpty {
                    estimatedCreditsText ?? L("Pending")
                } else {
                    "\(UsageFormatter.kiroCreditNumber(day.totalCreditsUsed)) credits"
                }
            return DailyCreditUsageRow(dayText: dayText, creditsText: creditsText, isEstimated: isEstimated)
        }
        return rows.isEmpty ? nil : rows
    }

    static func creditsDailyUsageFootnoteText(input: Input) -> String? {
        guard let rows = creditsDailyUsageRows(input: input), rows.contains(where: \.isEstimated) else { return nil }
        return L("* Estimated from usage")
    }

    private static func startOfWeek(containing date: Date, calendar: Calendar) -> Date {
        var normalized = calendar
        normalized.firstWeekday = 2
        normalized.timeZone = calendar.timeZone
        return normalized.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }

    private static func dayLabel(for day: String) -> String? {
        let formatter = Self.usageDayFormatter
        guard let date = formatter.date(from: day) else { return nil }
        return Self.usageDayDisplayFormatter.string(from: date)
    }

    private static func estimatedCreditsText(
        input: Input,
        breakdown: [OpenAIDashboardDailyBreakdown],
        todayKey: String)
        -> String?
    {
        guard let tokenSnapshot = input.tokenSnapshot else { return nil }
        let todayCost = tokenSnapshot.daily.first(where: { $0.date == todayKey })?.costUSD
            ?? tokenSnapshot.sessionCostUSD
        guard let todayCost, todayCost > 0 else { return nil }

        let inferredCreditsPerUSD = Self.inferredCreditsPerUSD(
            tokenSnapshot: tokenSnapshot,
            breakdown: breakdown,
            todayKey: todayKey)
        guard let inferredCreditsPerUSD, inferredCreditsPerUSD.isFinite, inferredCreditsPerUSD > 0 else { return nil }

        let estimatedCredits = max(0, todayCost * inferredCreditsPerUSD)
        return String(format: L("~ %@ credits*"), UsageFormatter.kiroCreditNumber(estimatedCredits))
    }

    private static func inferredCreditsPerUSD(
        tokenSnapshot: CostUsageTokenSnapshot,
        breakdown: [OpenAIDashboardDailyBreakdown],
        todayKey: String)
        -> Double?
    {
        let historicalCreditsByDay = Dictionary(
            uniqueKeysWithValues: breakdown
                .filter { $0.day != todayKey && $0.totalCreditsUsed > 0 }
                .map { ($0.day, $0.totalCreditsUsed) })

        let matchedPairs = tokenSnapshot.daily.compactMap { entry -> (Double, Double)? in
            guard entry.date != todayKey,
                  let costUSD = entry.costUSD,
                  costUSD > 0,
                  let creditsUsed = historicalCreditsByDay[entry.date]
            else {
                return nil
            }
            return (creditsUsed, costUSD)
        }
        guard !matchedPairs.isEmpty else { return nil }

        let totalCredits = matchedPairs.reduce(0) { $0 + $1.0 }
        let totalCostUSD = matchedPairs.reduce(0) { $0 + $1.1 }
        guard totalCostUSD > 0 else { return nil }
        return totalCredits / totalCostUSD
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
    let creditsDailyUsageHeaderText: String?
    let creditsDailyUsageRows: [UsageMenuCardView.Model.DailyCreditUsageRow]?
    let creditsDailyUsageFootnoteText: String?
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
                    Text(self.creditsDailyUsageHeaderText ?? L("Monday to date"))
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
                    if let creditsDailyUsageFootnoteText, !creditsDailyUsageFootnoteText.isEmpty {
                        Text(creditsDailyUsageFootnoteText)
                            .font(.footnote)
                            .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                            .fixedSize(horizontal: false, vertical: true)
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
