import CodexBarCore

extension UsageMenuCardView.Model {
    static func planDisplay(_ text: String, for provider: UsageProvider) -> String {
        if provider == .minimax {
            return self.miniMaxPlanDisplay(text)
        }
        let cleaned = if provider == .codex {
            CodexPlanFormatting.displayName(text) ?? UsageFormatter.cleanPlanName(text)
        } else {
            UsageFormatter.cleanPlanName(text)
        }
        return cleaned.isEmpty ? text : cleaned
    }

    private static func miniMaxPlanDisplay(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.lowercased()
        if normalized.contains("tokenplanplus") || normalized.contains("token plan plus") {
            return "Plus"
        }
        if normalized.contains("tokenplanmax") || normalized.contains("token plan max") {
            return "Max"
        }
        if normalized.contains("tokenplanultra") || normalized.contains("token plan ultra") {
            return "Ultra"
        }
        return trimmed
    }
}
