import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

struct MenuCardModelCodexCreditsTests {
    @Test
    func `codex credits card shows monday to date usage`() throws {
        let formatter = ISO8601DateFormatter()
        let now = try #require(formatter.date(from: "2026-06-10T12:00:00Z"))
        let metadata = try #require(ProviderDefaults.metadata[.codex])
        let june9 = try #require(formatter.date(from: "2026-06-09T09:00:00Z"))
        let june8 = try #require(formatter.date(from: "2026-06-08T09:00:00Z"))
        let dashboard = OpenAIDashboardSnapshot(
            signedInEmail: "codex@example.com",
            codeReviewRemainingPercent: nil,
            creditEvents: [
                CreditEvent(date: june9, service: "CLI", creditsUsed: 4),
                CreditEvent(date: june8, service: "CLI", creditsUsed: 6),
            ],
            dailyBreakdown: [],
            usageBreakdown: [
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-09",
                    services: [
                        OpenAIDashboardServiceUsage(service: "CLI", creditsUsed: 4),
                    ],
                    totalCreditsUsed: 4),
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-08",
                    services: [
                        OpenAIDashboardServiceUsage(service: "CLI", creditsUsed: 6),
                    ],
                    totalCreditsUsed: 6),
            ],
            creditsPurchaseURL: nil,
            creditsRemaining: 42,
            updatedAt: now)
        let model = UsageMenuCardView.Model.make(.init(
            provider: .codex,
            metadata: metadata,
            snapshot: nil,
            credits: CreditsSnapshot(remaining: 42, events: [], updatedAt: now),
            creditsError: nil,
            dashboard: dashboard,
            dashboardError: nil,
            tokenSnapshot: nil,
            tokenError: nil,
            account: AccountInfo(email: "codex@example.com", plan: "business"),
            isRefreshing: false,
            lastError: nil,
            usageBarsShowUsed: false,
            resetTimeDisplayStyle: .countdown,
            tokenCostUsageEnabled: false,
            showOptionalCreditsAndExtraUsage: true,
            hidePersonalInfo: false,
            now: now))

        #expect(model.creditsText == "42 left")
        #expect(model.creditsUsageSinceMondayText == "10 credits used since Monday")
        #expect(model.creditsDailyUsageRows?.map(\.dayText) == ["Jun 9", "Jun 8"])
        #expect(model.creditsDailyUsageRows?.map(\.creditsText) == ["4 credits", "6 credits"])
    }
}
