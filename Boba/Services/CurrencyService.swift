import Foundation

/// Currency formatting service with multi-currency support.
/// Uses the device locale for number formatting and ISO 4217 currency codes.
final class CurrencyService {
    static let shared = CurrencyService()

    private var formatters: [String: NumberFormatter] = [:]

    private init() {}

    /// Format a Decimal amount with the given currency code.
    func format(_ amount: Decimal, currencyCode: String, showSign: Bool = false) -> String {
        let formatter = getFormatter(for: currencyCode)
        let number = NSDecimalNumber(decimal: amount)

        if showSign && amount > 0 {
            return "+\(formatter.string(from: number) ?? "\(amount)")"
        }
        return formatter.string(from: number) ?? "\(amount)"
    }

    /// Format with explicit sign for income/expense display.
    func formatSigned(_ amount: Decimal, currencyCode: String, type: TransactionType) -> String {
        let formatter = getFormatter(for: currencyCode)
        let number = NSDecimalNumber(decimal: amount)
        let formatted = formatter.string(from: number) ?? "\(amount)"

        switch type {
        case .income: return "+\(formatted)"
        case .expense: return "-\(formatted)"
        case .transfer: return formatted
        }
    }

    /// Just the currency symbol for a given code.
    func symbol(for currencyCode: String) -> String {
        let formatter = getFormatter(for: currencyCode)
        return formatter.currencySymbol ?? currencyCode
    }

    /// Common currencies with their display names.
    static let commonCurrencies: [(code: String, name: String, symbol: String)] = [
        ("EUR", "Euro", "€"),
        ("USD", "US Dollar", "$"),
        ("GBP", "British Pound", "£"),
        ("HUF", "Hungarian Forint", "Ft"),
        ("CHF", "Swiss Franc", "CHF"),
        ("JPY", "Japanese Yen", "¥"),
        ("CAD", "Canadian Dollar", "CA$"),
        ("AUD", "Australian Dollar", "A$"),
        ("SEK", "Swedish Krona", "kr"),
        ("NOK", "Norwegian Krone", "kr"),
        ("DKK", "Danish Krone", "kr"),
        ("PLN", "Polish Złoty", "zł"),
        ("CZK", "Czech Koruna", "Kč"),
        ("RON", "Romanian Leu", "lei"),
        ("BGN", "Bulgarian Lev", "лв"),
        ("HRK", "Croatian Kuna", "kn"),
        ("TRY", "Turkish Lira", "₺"),
        ("BRL", "Brazilian Real", "R$"),
        ("MXN", "Mexican Peso", "MX$"),
        ("INR", "Indian Rupee", "₹"),
        ("CNY", "Chinese Yuan", "¥"),
        ("KRW", "South Korean Won", "₩"),
    ]

    /// Get the device's default currency code.
    static var deviceCurrencyCode: String {
        Locale.current.currency?.identifier ?? "EUR"
    }

    // MARK: - Private

    private func getFormatter(for currencyCode: String) -> NumberFormatter {
        if let cached = formatters[currencyCode] {
            return cached
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        // For currencies like JPY, HUF that don't use decimals
        let noDecimalCurrencies = ["JPY", "HUF", "KRW", "VND", "CLP"]
        if noDecimalCurrencies.contains(currencyCode) {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
        }

        formatters[currencyCode] = formatter
        return formatter
    }
}
