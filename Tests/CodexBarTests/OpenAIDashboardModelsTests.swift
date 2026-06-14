import CodexBarCore
import Foundation
import Testing

struct OpenAIDashboardModelsTests {
    @Test
    func `removes skill usage services from usage breakdown`() {
        let breakdown = [
            OpenAIDashboardDailyBreakdown(
                day: "2026-04-30",
                services: [
                    OpenAIDashboardServiceUsage(service: "Desktop App", creditsUsed: 10),
                    OpenAIDashboardServiceUsage(service: "Skillusage:imagegen", creditsUsed: 7),
                    OpenAIDashboardServiceUsage(service: " skillusage:github:github ", creditsUsed: 2),
                ],
                totalCreditsUsed: 19),
            OpenAIDashboardDailyBreakdown(
                day: "2026-04-29",
                services: [
                    OpenAIDashboardServiceUsage(service: "Skillusage:deep Research", creditsUsed: 3),
                ],
                totalCreditsUsed: 3),
        ]

        let filtered = OpenAIDashboardDailyBreakdown.removingSkillUsageServices(from: breakdown)

        #expect(filtered == [
            OpenAIDashboardDailyBreakdown(
                day: "2026-04-30",
                services: [
                    OpenAIDashboardServiceUsage(service: "Desktop App", creditsUsed: 10),
                ],
                totalCreditsUsed: 10),
        ])
    }

    @Test
    func `snapshot initializer sanitizes usage breakdown`() {
        let snapshot = OpenAIDashboardSnapshot(
            signedInEmail: "codex@example.com",
            codeReviewRemainingPercent: nil,
            creditEvents: [],
            dailyBreakdown: [],
            usageBreakdown: [
                OpenAIDashboardDailyBreakdown(
                    day: "2026-04-30",
                    services: [
                        OpenAIDashboardServiceUsage(service: "CLI", creditsUsed: 4),
                        OpenAIDashboardServiceUsage(service: "Skillusage:pdf Renderer", creditsUsed: 6),
                    ],
                    totalCreditsUsed: 10),
            ],
            creditsPurchaseURL: nil,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000))

        #expect(snapshot.usageBreakdown == [
            OpenAIDashboardDailyBreakdown(
                day: "2026-04-30",
                services: [
                    OpenAIDashboardServiceUsage(service: "CLI", creditsUsed: 4),
                ],
                totalCreditsUsed: 4),
        ])
    }

    @Test
    func `snapshot decoder drops empty zero usage buckets`() throws {
        let json = """
        {
          "signedInEmail": "codex@example.com",
          "codeReviewRemainingPercent": null,
          "creditEvents": [],
          "dailyBreakdown": [],
          "usageBreakdown": [
            { "day": "2026-04-30", "services": [], "totalCreditsUsed": 0 },
            { "day": "2026-04-29", "services": [], "totalCreditsUsed": 4 }
          ],
          "creditsPurchaseURL": null,
          "updatedAt": "2026-04-30T19:27:07Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let snapshot = try decoder.decode(OpenAIDashboardSnapshot.self, from: Data(json.utf8))

        #expect(snapshot.usageBreakdown == [
            OpenAIDashboardDailyBreakdown(
                day: "2026-04-29",
                services: [],
                totalCreditsUsed: 4),
        ])
    }

    @Test
    func `credits used since last monday does not infer from credit events alone`() throws {
        let calendar = Calendar(identifier: .gregorian)
        let formatter = ISO8601DateFormatter()
        let now = try #require(formatter.date(from: "2026-06-10T12:00:00Z"))
        let june9 = try #require(formatter.date(from: "2026-06-09T09:00:00Z"))
        let june8 = try #require(formatter.date(from: "2026-06-08T09:00:00Z"))
        let june7 = try #require(formatter.date(from: "2026-06-07T09:00:00Z"))
        let events = [
            CreditEvent(date: june9, service: "CLI", creditsUsed: 4),
            CreditEvent(date: june8, service: "CLI", creditsUsed: 6),
            CreditEvent(date: june7, service: "CLI", creditsUsed: 10),
        ]
        let snapshot = OpenAIDashboardSnapshot(
            signedInEmail: "codex@example.com",
            codeReviewRemainingPercent: nil,
            creditEvents: events,
            dailyBreakdown: [],
            usageBreakdown: [],
            creditsPurchaseURL: nil,
            updatedAt: now)

        #expect(snapshot.creditsUsedSinceLastMonday(now: now, calendar: calendar) == 0)
    }

    @Test
    func `credits used since last monday sums usage breakdown days when weekly total is missing`() throws {
        let calendar = Calendar(identifier: .gregorian)
        let formatter = ISO8601DateFormatter()
        let now = try #require(formatter.date(from: "2026-06-13T12:00:00Z"))
        let snapshot = OpenAIDashboardSnapshot(
            signedInEmail: "codex@example.com",
            codeReviewRemainingPercent: nil,
            creditEvents: [],
            dailyBreakdown: [],
            usageBreakdown: [
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-13",
                    services: [],
                    totalCreditsUsed: 30.85015281125154),
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-12",
                    services: [],
                    totalCreditsUsed: 41.246982343855855),
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-11",
                    services: [],
                    totalCreditsUsed: 43.27701995280202),
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-10",
                    services: [],
                    totalCreditsUsed: 5.794017570691705),
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-09",
                    services: [],
                    totalCreditsUsed: 19.26621188957122),
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-08",
                    services: [],
                    totalCreditsUsed: 23.15572807205256),
            ],
            creditsPurchaseURL: nil,
            updatedAt: now)

        #expect(
            abs((snapshot.creditsUsedSinceLastMonday(now: now, calendar: calendar) ?? 0) -
                163.5901126402249) < 0.000001)
    }

    @Test
    func `display usage breakdown fills current week through today`() throws {
        let calendar = Calendar(identifier: .gregorian)
        let formatter = ISO8601DateFormatter()
        let now = try #require(formatter.date(from: "2026-06-14T12:00:00Z"))
        let snapshot = OpenAIDashboardSnapshot(
            signedInEmail: "codex@example.com",
            codeReviewRemainingPercent: nil,
            creditEvents: [],
            dailyBreakdown: [],
            usageBreakdown: [
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-13",
                    services: [
                        OpenAIDashboardServiceUsage(service: "Desktop App", creditsUsed: 85.52889387070745),
                    ],
                    totalCreditsUsed: 85.52889387070745),
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-12",
                    services: [
                        OpenAIDashboardServiceUsage(service: "Desktop App", creditsUsed: 41.246982343855855),
                    ],
                    totalCreditsUsed: 41.246982343855855),
                OpenAIDashboardDailyBreakdown(
                    day: "2026-06-11",
                    services: [
                        OpenAIDashboardServiceUsage(service: "Desktop App", creditsUsed: 43.27701995280202),
                    ],
                    totalCreditsUsed: 43.27701995280202),
            ],
            creditsPurchaseURL: nil,
            updatedAt: now)

        let days = snapshot.displayUsageBreakdown(now: now, calendar: calendar)

        #expect(days.map(\.day) == [
            "2026-06-14",
            "2026-06-13",
            "2026-06-12",
            "2026-06-11",
            "2026-06-10",
            "2026-06-09",
            "2026-06-08",
        ])
        #expect(days.first?.totalCreditsUsed == 0)
        #expect(days.last?.day == "2026-06-08")
    }

    @Test
    func `credits used since last monday prefers explicit weekly summary`() throws {
        let calendar = Calendar(identifier: .gregorian)
        let formatter = ISO8601DateFormatter()
        let now = try #require(formatter.date(from: "2026-06-13T12:00:00Z"))
        let snapshot = OpenAIDashboardSnapshot(
            signedInEmail: "codex@example.com",
            codeReviewRemainingPercent: nil,
            creditEvents: [],
            dailyBreakdown: [],
            usageBreakdown: [],
            weeklyCreditsUsed: 715,
            creditsPurchaseURL: nil,
            updatedAt: now)

        #expect(snapshot.creditsUsedSinceLastMonday(now: now, calendar: calendar) == 715)
    }

    @Test
    func `daily breakdown keeps distinct day totals`() throws {
        let formatter = ISO8601DateFormatter()
        let june9 = try #require(formatter.date(from: "2026-06-09T09:00:00Z"))
        let june8 = try #require(formatter.date(from: "2026-06-08T09:00:00Z"))
        let june7 = try #require(formatter.date(from: "2026-06-07T09:00:00Z"))

        let breakdown = OpenAIDashboardSnapshot.makeDailyBreakdown(
            from: [
                CreditEvent(date: june9, service: "CLI", creditsUsed: 4),
                CreditEvent(date: june8, service: "CLI", creditsUsed: 6),
                CreditEvent(date: june7, service: "CLI", creditsUsed: 10),
            ],
            maxDays: 30)

        #expect(breakdown.map(\.day) == ["2026-06-09", "2026-06-08", "2026-06-07"])
        #expect(breakdown.map(\.totalCreditsUsed) == [4, 6, 10])
    }
}
