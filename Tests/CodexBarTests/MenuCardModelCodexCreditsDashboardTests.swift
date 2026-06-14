import CodexBarCore
import Foundation
import SwiftUI
import Testing
@testable import CodexBar

struct MenuCardModelCodexCreditsDashboardTests {
    private static func dailyCostEntry(_ date: String, tokens: Int, costUSD: Double) -> CostUsageDailyReport.Entry {
        .init(
            date: date,
            inputTokens: nil,
            outputTokens: nil,
            totalTokens: tokens,
            costUSD: costUSD,
            modelsUsed: nil,
            modelBreakdowns: nil)
    }

    @Test
    func `codex live card shows monday to date from attached dashboard`() throws {
        let formatter = ISO8601DateFormatter()
        let now = try #require(formatter.date(from: "2026-06-10T12:00:00Z"))
        let identity = ProviderIdentitySnapshot(
            providerID: .codex,
            accountEmail: "codex@example.com",
            accountOrganization: nil,
            loginMethod: "Plus Plan")
        let snapshot = UsageSnapshot(
            primary: RateWindow(
                usedPercent: 22,
                windowMinutes: 300,
                resetsAt: now.addingTimeInterval(3000),
                resetDescription: nil),
            secondary: RateWindow(
                usedPercent: 40,
                windowMinutes: 10080,
                resetsAt: now.addingTimeInterval(6000),
                resetDescription: nil),
            updatedAt: now,
            identity: identity)
        let metadata = try #require(ProviderDefaults.metadata[.codex])
        let dashboard = OpenAIDashboardSnapshot(
            signedInEmail: "codex@example.com",
            codeReviewRemainingPercent: 73,
            codeReviewLimit: RateWindow(
                usedPercent: 27,
                windowMinutes: nil,
                resetsAt: now.addingTimeInterval(3600),
                resetDescription: nil),
            creditEvents: [],
            dailyBreakdown: [
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-10",
                    services: [
                        OpenAIDashboardServiceUsage(service: "CLI", creditsUsed: 5),
                    ],
                    totalCreditsUsed: 5),
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-09",
                    services: [
                        OpenAIDashboardServiceUsage(service: "Desktop App", creditsUsed: 4),
                    ],
                    totalCreditsUsed: 4),
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-08",
                    services: [
                        OpenAIDashboardServiceUsage(service: "CLI", creditsUsed: 6),
                    ],
                    totalCreditsUsed: 6),
            ],
            usageBreakdown: [],
            creditsPurchaseURL: nil,
            updatedAt: now)
        let codexProjection = CodexConsumerProjection.make(
            surface: .liveCard,
            context: CodexConsumerProjection.Context(
                snapshot: snapshot,
                rawUsageError: nil,
                liveCredits: nil,
                rawCreditsError: nil,
                liveDashboard: dashboard,
                rawDashboardError: nil,
                dashboardAttachmentAuthorized: true,
                dashboardRequiresLogin: false,
                now: now))

        let model = UsageMenuCardView.Model.make(.init(
            provider: .codex,
            metadata: metadata,
            snapshot: snapshot,
            codexProjection: codexProjection,
            credits: nil,
            creditsError: nil,
            dashboard: dashboard,
            dashboardError: nil,
            tokenSnapshot: nil,
            tokenError: nil,
            account: AccountInfo(email: "codex@example.com", plan: "Plus Plan"),
            isRefreshing: false,
            lastError: nil,
            usageBarsShowUsed: true,
            resetTimeDisplayStyle: .countdown,
            tokenCostUsageEnabled: false,
            showOptionalCreditsAndExtraUsage: true,
            hidePersonalInfo: false,
            now: now))

        #expect(model.creditsUsageSinceMondayText == "15 credits used since Monday")
        #expect(model.creditsDailyUsageRows?.map(\.dayText) == ["Jun 10", "Jun 9", "Jun 8"])
        #expect(model.creditsDailyUsageRows?.map(\.creditsText) == ["5 credits", "4 credits", "6 credits"])
    }

    @Test
    func `codex live card estimates today's credits when dashboard day is still pending`() throws {
        let formatter = ISO8601DateFormatter()
        let now = try #require(formatter.date(from: "2026-06-14T12:00:00Z"))
        let identity = ProviderIdentitySnapshot(
            providerID: .codex,
            accountEmail: "codex@example.com",
            accountOrganization: nil,
            loginMethod: "Enterprise")
        let snapshot = UsageSnapshot(
            primary: RateWindow(
                usedPercent: 22,
                windowMinutes: 300,
                resetsAt: now.addingTimeInterval(3000),
                resetDescription: nil),
            secondary: RateWindow(
                usedPercent: 40,
                windowMinutes: 10080,
                resetsAt: now.addingTimeInterval(6000),
                resetDescription: nil),
            updatedAt: now,
            identity: identity)
        let metadata = try #require(ProviderDefaults.metadata[.codex])
        let dashboard = OpenAIDashboardSnapshot(
            signedInEmail: "codex@example.com",
            codeReviewRemainingPercent: 73,
            codeReviewLimit: RateWindow(
                usedPercent: 27,
                windowMinutes: nil,
                resetsAt: now.addingTimeInterval(3600),
                resetDescription: nil),
            creditEvents: [],
            dailyBreakdown: [
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-13",
                    services: [.init(service: "Desktop App", creditsUsed: 85.53)],
                    totalCreditsUsed: 85.53),
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-12",
                    services: [.init(service: "Desktop App", creditsUsed: 41.25)],
                    totalCreditsUsed: 41.25),
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-11",
                    services: [.init(service: "CLI", creditsUsed: 43.28)],
                    totalCreditsUsed: 43.28),
            ],
            usageBreakdown: [],
            creditsPurchaseURL: nil,
            updatedAt: now)
        let tokenSnapshot = CostUsageTokenSnapshot(
            sessionTokens: 35_000_000,
            sessionCostUSD: 3.69,
            last30DaysTokens: 417_000_000,
            last30DaysCostUSD: 142.10,
            daily: [
                Self.dailyCostEntry("2026-06-14", tokens: 35_000_000, costUSD: 3.69),
                Self.dailyCostEntry("2026-06-13", tokens: 90_000_000, costUSD: 8.553),
                Self.dailyCostEntry("2026-06-12", tokens: 44_000_000, costUSD: 4.125),
                Self.dailyCostEntry("2026-06-11", tokens: 45_000_000, costUSD: 4.328),
            ],
            updatedAt: now)
        let codexProjection = CodexConsumerProjection.make(
            surface: .liveCard,
            context: CodexConsumerProjection.Context(
                snapshot: snapshot,
                rawUsageError: nil,
                liveCredits: nil,
                rawCreditsError: nil,
                liveDashboard: dashboard,
                rawDashboardError: nil,
                dashboardAttachmentAuthorized: true,
                dashboardRequiresLogin: false,
                now: now))

        let model = UsageMenuCardView.Model.make(.init(
            provider: .codex,
            metadata: metadata,
            snapshot: snapshot,
            codexProjection: codexProjection,
            credits: nil,
            creditsError: nil,
            dashboard: dashboard,
            dashboardError: nil,
            tokenSnapshot: tokenSnapshot,
            tokenError: nil,
            account: AccountInfo(email: "codex@example.com", plan: "Enterprise"),
            isRefreshing: false,
            lastError: nil,
            usageBarsShowUsed: true,
            resetTimeDisplayStyle: .countdown,
            tokenCostUsageEnabled: true,
            showOptionalCreditsAndExtraUsage: true,
            hidePersonalInfo: false,
            now: now))

        #expect(
            model.creditsDailyUsageRows?.map(\.dayText) ==
                ["Jun 14", "Jun 13", "Jun 12", "Jun 11", "Jun 10", "Jun 9", "Jun 8"])
        #expect(model.creditsDailyUsageRows?.first?.creditsText == "~ 36.90 credits*")
        #expect(model.creditsDailyUsageRows?.first?.isEstimated == true)
        #expect(model.creditsDailyUsageFootnoteText == "* Estimated from usage")
    }
}
