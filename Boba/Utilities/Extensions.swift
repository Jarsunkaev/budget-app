import Foundation

// MARK: - Date Extensions

extension Date {
    /// Start of the current month.
    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }

    /// End of the current month.
    var endOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.end ?? self
    }

    /// Start of the current week.
    var startOfWeek: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: self)?.start ?? self
    }

    /// End of the current week.
    var endOfWeek: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: self)?.end ?? self
    }

    /// Start of the current year.
    var startOfYear: Date {
        Calendar.current.dateInterval(of: .year, for: self)?.start ?? self
    }

    /// Formatted as a relative day string (Today, Yesterday, or weekday/date).
    var relativeDayString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if calendar.isDate(self, equalTo: .now, toGranularity: .weekOfYear) {
            return self.formatted(.dateTime.weekday(.wide))
        } else {
            return self.formatted(.dateTime.month(.abbreviated).day())
        }
    }

    /// Short month/year label.
    var monthYearString: String {
        self.formatted(.dateTime.month(.wide).year())
    }

    /// Number of days remaining in the current month.
    var daysRemainingInMonth: Int {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: self) else { return 0 }
        let currentDay = calendar.component(.day, from: self)
        return range.count - currentDay
    }
}

// MARK: - Decimal Extensions

extension Decimal {
    /// Convert to Double for charts and calculations.
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    /// Absolute value.
    var abs: Decimal {
        self < 0 ? -self : self
    }
}

// MARK: - Array Extensions

extension Array {
    /// Safe subscript that returns nil if index is out of bounds.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
