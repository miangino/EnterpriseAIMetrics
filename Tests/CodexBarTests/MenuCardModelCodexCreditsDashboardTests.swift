import CodexBarCore
import Foundation
import SwiftUI
import Testing
@testable import CodexBar

struct MenuCardModelCodexCreditsDashboardTests {
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
}
