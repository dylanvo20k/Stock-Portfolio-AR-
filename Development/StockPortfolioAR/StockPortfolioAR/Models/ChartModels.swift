import Foundation

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
}

enum ChartTimeframe: String, CaseIterable {
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case oneYear = "1Y"
    case all = "ALL"
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .oneDay:
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        case .oneWeek:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            return calendar.date(byAdding: .year, value: -5, to: now) ?? now
        }
    }
    
    var dateComponent: Calendar.Component {
        switch self {
        case .oneDay:
            return .hour
        case .oneWeek, .oneMonth:
            return .day
        case .threeMonths:
            return .weekOfYear
        case .oneYear, .all:
            return .month
        }
    }
    
    var maxDataPoints: Int {
        switch self {
        case .oneDay:
            return 24 // Hourly
        case .oneWeek:
            return 7 // Daily
        case .oneMonth:
            return 30 // Daily
        case .threeMonths:
            return 12 // Weekly
        case .oneYear:
            return 12 // Monthly
        case .all:
            return 20 // Every 3 months
        }
    }
}
