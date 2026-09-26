import Foundation
import SwiftData
import SwiftUI

/// Intelligence Service for Boba.
/// Provides smart auto-categorization, natural language parsing, spending anomaly detection, and smart reporting insights.
@Observable
final class FoundationModelsService {
    static let shared = FoundationModelsService()

    // MARK: - Parsed Voice Transaction Result

    struct ParsedVoiceTransaction: Sendable {
        let amount: Decimal?
        let currencyCode: String?
        let type: TransactionType
        let category: Category?
        let note: String
        let confidenceScore: Double
    }

    // MARK: - AI-Generated Spending Insight

    struct SpendingInsight: Identifiable, Sendable {
        let id: UUID
        let title: String
        let message: String
        let type: InsightType
        let categoryName: String?
        let categoryIcon: String?
        let categoryColorHex: String?
        let actionTitle: String?
        let metricBadge: String?

        init(
            id: UUID = UUID(),
            title: String,
            message: String,
            type: InsightType,
            categoryName: String? = nil,
            categoryIcon: String? = nil,
            categoryColorHex: String? = nil,
            actionTitle: String? = nil,
            metricBadge: String? = nil
        ) {
            self.id = id
            self.title = title
            self.message = message
            self.type = type
            self.categoryName = categoryName
            self.categoryIcon = categoryIcon
            self.categoryColorHex = categoryColorHex
            self.actionTitle = actionTitle
            self.metricBadge = metricBadge
        }

        enum InsightType: String, Sendable {
            case anomaly
            case forecast
            case envelopeWarning
            case savingOpportunity
            case positiveStreak
            case subscriptionAudit
        }
    }

    // MARK: - Voice Natural Language Parsing

    /// Parses spoken or typed natural language strings (e.g. "I sent 16,000 forints for utilities")
    /// into structured transaction properties.
    func parseVoicePrompt(
        _ prompt: String,
        categories: [Category],
        accounts: [Account],
        defaultCurrency: String = "EUR"
    ) -> ParsedVoiceTransaction {
        let rawPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawPrompt.isEmpty else {
            return ParsedVoiceTransaction(
                amount: nil,
                currencyCode: defaultCurrency,
                type: .expense,
                category: nil,
                note: "",
                confidenceScore: 0
            )
        }

        let lowerPrompt = rawPrompt.lowercased()

        // 1. Extract Amount & match string (handles 16,000 / 16.000 / 16 000 / 320k / 1.5k / 15.5)
        let (extractedAmount, matchedNumStr) = parseAmount(from: rawPrompt)

        // 2. Extract Currency
        let extractedCurrency = extractCurrency(from: lowerPrompt) ?? defaultCurrency

        // 3. Determine Transaction Type
        let type: TransactionType
        if lowerPrompt.contains("received") || lowerPrompt.contains("earned") || lowerPrompt.contains("salary") || lowerPrompt.contains("got paid") || lowerPrompt.contains("income") || lowerPrompt.contains("paycheck") || lowerPrompt.contains("deposit") {
            type = .income
        } else if lowerPrompt.contains("transfer") || lowerPrompt.contains("moved") || lowerPrompt.contains("sent to savings") {
            type = .transfer
        } else {
            type = .expense
        }

        // 4. Predict Category (Matches dynamically against user categories)
        let category = predictCategory(for: lowerPrompt, categories: categories)

        // 5. Clean Note Text without mangling words or leaving leading commas/prepositions
        var cleanNote = rawPrompt

        // Remove exact matched number string
        if !matchedNumStr.isEmpty {
            cleanNote = cleanNote.replacingOccurrences(of: matchedNumStr, with: "", options: .caseInsensitive)
        }

        // Remove currency terms safely using regex word boundaries
        let currencyPatterns = [
            "\\bhuf\\b", "\\bft\\b", "\\bforint\\b", "\\bforints\\b",
            "\\beur\\b", "\\beuro\\b", "\\beuros\\b",
            "\\busd\\b", "\\bdollar\\b", "\\bdollars\\b",
            "\\bgbp\\b", "\\bchf\\b", "€", "\\$", "£"
        ]
        for pat in currencyPatterns {
            cleanNote = cleanNote.replacingOccurrences(of: pat, with: "", options: [.regularExpression, .caseInsensitive])
        }

        // Remove filler verbs / prepositions using regex word boundaries so words like "dining" or "internet" are not mangled!
        let noisePatterns = [
            "\\bi\\b", "\\bsent\\b", "\\btransferred\\b", "\\bspent\\b", "\\bpaid\\b", "\\bbought\\b", "\\bgot\\b",
            "\\bfor\\b", "\\bin\\b", "\\bon\\b", "\\bat\\b", "\\bto\\b", "\\bthe\\b", "\\ba\\b", "\\ban\\b"
        ]
        for pat in noisePatterns {
            cleanNote = cleanNote.replacingOccurrences(of: pat, with: "", options: [.regularExpression, .caseInsensitive])
        }

        // Remove any orphan leading punctuation like commas or dots
        cleanNote = cleanNote.replacingOccurrences(of: "^[^a-zA-Z0-9]+", with: "", options: .regularExpression)
        cleanNote = cleanNote.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let finalNote = cleanNote.isEmpty ? (category?.name ?? (type == .transfer ? "Account Transfer" : "Voice Entry")) : cleanNote.capitalized

        let score: Double = (extractedAmount != nil ? 0.5 : 0.0) + (category != nil ? 0.3 : 0.1) + (!finalNote.isEmpty ? 0.2 : 0.0)

        return ParsedVoiceTransaction(
            amount: extractedAmount,
            currencyCode: extractedCurrency,
            type: type,
            category: category,
            note: finalNote,
            confidenceScore: score
        )
    }

    private func parseAmount(from text: String) -> (Decimal?, String) {
        // Matches numbers with thousand separators (comma, dot, space) or multipliers (k/m)
        let regexPattern = "(?:\\b|\\$|€|£)(\\d{1,3}(?:[.,\\s]\\d{3})*(?:[.,]\\d{1,2})?|\\d+(?:[.,]\\d+)?)\\s*([kmKM])?\\b"
        guard let regex = try? NSRegularExpression(pattern: regexPattern) else { return (nil, "") }

        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            guard match.numberOfRanges >= 2 else { continue }
            let rawNumMatched = nsString.substring(with: match.range(at: 1))
            let fullMatchedStr = nsString.substring(with: match.range)

            var cleanNumStr = rawNumMatched.replacingOccurrences(of: " ", with: "")

            if cleanNumStr.contains(",") && cleanNumStr.contains(".") {
                cleanNumStr = cleanNumStr.replacingOccurrences(of: ",", with: "")
            } else if cleanNumStr.contains(",") {
                let parts = cleanNumStr.components(separatedBy: ",")
                if parts.count == 2 && parts[1].count == 3 {
                    // e.g. "16,000" -> thousands separator!
                    cleanNumStr = parts.joined()
                } else if parts.count > 2 {
                    cleanNumStr = parts.joined()
                } else {
                    // e.g. "15,5" -> decimal comma
                    cleanNumStr = cleanNumStr.replacingOccurrences(of: ",", with: ".")
                }
            } else if cleanNumStr.contains(".") {
                let parts = cleanNumStr.components(separatedBy: ".")
                if parts.count == 2 && parts[1].count == 3 {
                    // e.g. "16.000" -> thousands separator!
                    cleanNumStr = parts.joined()
                } else if parts.count > 2 {
                    cleanNumStr = parts.joined()
                }
            }

            if var baseVal = Double(cleanNumStr) {
                if match.numberOfRanges >= 3 {
                    let suffixRange = match.range(at: 2)
                    if suffixRange.location != NSNotFound {
                        let suffix = nsString.substring(with: suffixRange).lowercased()
                        if suffix == "k" {
                            baseVal *= 1000
                        } else if suffix == "m" {
                            baseVal *= 1000000
                        }
                    }
                }
                return (Decimal(baseVal), fullMatchedStr)
            }
        }

        return (nil, "")
    }

    private func extractCurrency(from text: String) -> String? {
        let currencyMappings: [String: [String]] = [
            "HUF": ["huf", "ft", "forint", "forints", "hufs"],
            "EUR": ["eur", "euro", "euros", "€"],
            "USD": ["usd", "dollar", "dollars", "$"],
            "GBP": ["gbp", "pound", "pounds", "£"],
            "CHF": ["chf", "franc"],
            "CAD": ["cad"],
            "AUD": ["aud"]
        ]

        for (code, keywords) in currencyMappings {
            for kw in keywords {
                if text.contains(kw) {
                    return code
                }
            }
        }
        return nil
    }

    // MARK: - Auto-Categorization

    /// Predict category for a given merchant/note using pattern matching.
    func predictCategory(for note: String, categories: [Category]) -> Category? {
        let cleanText = note.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return nil }

        // First check exact category name match in user's categories
        for cat in categories {
            if cleanText.contains(cat.name.lowercased()) {
                return cat
            }
        }

        let categoryMappings: [String: [String]] = [
            "Rent": ["rent", "landlord", "apartment", "lease", "housing", "lakas", "alberlet"],
            "Utilities": ["utility", "utilities", "electric", "electricity", "water", "gas", "internet", "vodafone", "telekom", "yettel", "bill", "bills", "insurance"],
            "Groceries": ["supermarket", "grocery", "groceries", "walmart", "target", "tesco", "lidl", "aldi", "spar", "penny", "auchan", "coop", "market", "piac"],
            "Coffee": ["starbucks", "costa", "cafe", "espresso", "barista", "kave", "coffee", "roastery", "matcha"],
            "Dining": ["restaurant", "bistro", "burger", "pizza", "sushi", "mcdonald", "kfc", "eats", "wolt", "foodora", "uber eats", "diner", "etterem", "ebed", "food"],
            "Subscriptions": ["netflix", "spotify", "apple.com", "google", "patreon", "youtube", "hbo", "disney", "prime", "chatgpt", "icloud", "sub", "subscription"],
            "Transport": ["uber", "bolt", "taxi", "gas", "shell", "bp", "mol", "omv", "fuel", "parking", "bkv", "transit", "metro", "bus", "train", "mav"],
            "Shopping": ["amazon", "zara", "h&m", "nike", "adidas", "mall", "store", "clothing", "electronics", "ikea"],
            "Entertainment": ["cinema", "movie", "bowling", "concert", "ticket", "game", "steam", "playstation", "xbox"],
            "Healthcare": ["pharmacy", "doctor", "dental", "gyogyszertar", "clinic", "hospital", "medicine", "health"],
            "Travel": ["flight", "airline", "wizz", "ryanair", "hotel", "airbnb", "booking", "resort", "vacation"],
            "Savings": ["savings", "investment", "deposit", "transfer to savings", "emergency fund", "stock", "crypto"]
        ]

        for (categoryKey, keywords) in categoryMappings {
            for keyword in keywords {
                if cleanText.contains(keyword) {
                    if let matched = categories.first(where: { $0.name.lowercased().contains(categoryKey.lowercased()) }) {
                        return matched
                    }
                }
            }
        }

        return categories.first
    }

    // MARK: - Smart Insights Generation (Reporting Tab)

    /// Generate AI financial insights.
    func generateInsights(transactions: [Transaction], budgets: [Budget], categories: [Category], currencyCode: String = "EUR") -> [SpendingInsight] {
        var insights: [SpendingInsight] = []
        let now = Date()
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return [] }

        let monthTransactions = transactions.filter { $0.date >= startOfMonth }
        let totalExpenses = monthTransactions.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        let totalIncome = monthTransactions.filter { $0.type == .income }.reduce(Decimal(0)) { $0 + $1.amount }

        // Insight 1: Spending Anomaly Detection
        let diningTransactions = monthTransactions.filter {
            $0.category?.name.lowercased().contains("dining") == true ||
            $0.category?.name.lowercased().contains("food") == true ||
            $0.note.lowercased().contains("wolt") ||
            $0.note.lowercased().contains("bolt")
        }
        let diningTotal = diningTransactions.reduce(Decimal(0)) { $0 + $1.amount }

        if diningTotal > 0 && totalExpenses > 0 {
            let ratio = NSDecimalNumber(decimal: diningTotal / totalExpenses).doubleValue
            if ratio > 0.25 {
                let formattedDining = CurrencyService.shared.format(diningTotal, currencyCode: currencyCode)
                insights.append(
                    SpendingInsight(
                        title: "High Dining & Takeout Velocity",
                        message: "Dining & delivery accounts for \(Int(ratio * 100))% (\(formattedDining)) of your expenses this month.",
                        type: .anomaly,
                        categoryName: "Dining",
                        categoryIcon: "fork.knife",
                        categoryColorHex: "d1603d",
                        actionTitle: "Review Dining",
                        metricBadge: "+\(Int(ratio * 100))% share"
                    )
                )
            }
        }

        // Insight 2: Envelope Budget Limits & Forecasts
        for budget in budgets {
            guard let category = budget.category else { continue }
            let categorySpent = monthTransactions
                .filter { $0.category?.id == category.id && $0.type == .expense }
                .reduce(Decimal(0)) { $0 + $1.amount }

            if budget.limitAmount > 0 {
                let ratio = NSDecimalNumber(decimal: categorySpent / budget.limitAmount).doubleValue
                if ratio >= 0.85 && ratio < 1.0 {
                    let rem = budget.limitAmount - categorySpent
                    let formattedRem = CurrencyService.shared.format(rem, currencyCode: budget.currencyCode)
                    insights.append(
                        SpendingInsight(
                            title: "\(category.name) Near Limit",
                            message: "You have used \(Int(ratio * 100))% of your \(category.name) envelope. \(formattedRem) left for remaining days.",
                            type: .envelopeWarning,
                            categoryName: category.name,
                            categoryIcon: category.icon,
                            categoryColorHex: category.colorHex,
                            actionTitle: "Adjust Envelope",
                            metricBadge: "\(Int(ratio * 100))% used"
                        )
                    )
                } else if ratio >= 1.0 {
                    let overage = categorySpent - budget.limitAmount
                    let formattedOver = CurrencyService.shared.format(overage, currencyCode: budget.currencyCode)
                    insights.append(
                        SpendingInsight(
                            title: "\(category.name) Envelope Exceeded",
                            message: "Over budget by \(formattedOver). Auto-rollover will balance from surplus envelopes next period.",
                            type: .envelopeWarning,
                            categoryName: category.name,
                            categoryIcon: category.icon,
                            categoryColorHex: category.colorHex,
                            actionTitle: "Rebalance",
                            metricBadge: "Exceeded"
                        )
                    )
                }
            }
        }

        // Insight 3: Rollover & Savings Opportunity
        let activeRollovers = budgets.filter { $0.autoRolloverToSavings }
        if !activeRollovers.isEmpty {
            var potentialRollover: Decimal = 0
            for b in activeRollovers {
                let spent = monthTransactions.filter { $0.category?.id == b.category?.id && $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
                if b.limitAmount > spent {
                    potentialRollover += (b.limitAmount - spent)
                }
            }
            if potentialRollover > 0 {
                let formattedRollover = CurrencyService.shared.format(potentialRollover, currencyCode: currencyCode)
                insights.append(
                    SpendingInsight(
                        title: "Auto-Rollover Projected",
                        message: "You are on track to automatically sweep \(formattedRollover) into your savings at month end.",
                        type: .savingOpportunity,
                        categoryName: "Savings",
                        categoryIcon: "leaf.fill",
                        categoryColorHex: "d0e37f",
                        actionTitle: "View Rollovers",
                        metricBadge: formattedRollover
                    )
                )
            }
        }

        // Insight 4: Recurring Subscriptions Audit
        let subscriptionTx = monthTransactions.filter { $0.category?.name.lowercased().contains("sub") == true || $0.isRecurring }
        let subscriptionSpent = subscriptionTx.reduce(Decimal(0)) { $0 + $1.amount }
        if subscriptionSpent > 0 {
            let formattedSub = CurrencyService.shared.format(subscriptionSpent, currencyCode: currencyCode)
            insights.append(
                SpendingInsight(
                    title: "Active Subscriptions Audit",
                    message: "\(subscriptionTx.count) recurring payments logged this month totaling \(formattedSub).",
                    type: .subscriptionAudit,
                    categoryName: "Subscriptions",
                    categoryIcon: "arrow.2.squarepath",
                    categoryColorHex: "ddb967",
                    actionTitle: "Audit Services",
                    metricBadge: "\(subscriptionTx.count) active"
                )
            )
        }

        // Insight 5: Positive Savings Streak
        if totalIncome > totalExpenses && totalExpenses > 0 {
            let net = totalIncome - totalExpenses
            let savingsRate = NSDecimalNumber(decimal: (net / totalIncome) * 100).intValue
            insights.append(
                SpendingInsight(
                    title: "\(savingsRate)% Net Savings Rate",
                    message: "You are spending significantly less than you earn. Great job maintaining a healthy financial buffer!",
                    type: .positiveStreak,
                    categoryName: "Cashflow",
                    categoryIcon: "sparkles",
                    categoryColorHex: "d0e37f",
                    actionTitle: "Financial Health",
                    metricBadge: "+\(savingsRate)%"
                )
            )
        }

        return insights
    }
}
