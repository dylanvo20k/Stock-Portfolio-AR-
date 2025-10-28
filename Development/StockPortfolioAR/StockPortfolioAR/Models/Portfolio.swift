import Foundation
import SwiftData

@Model
class Portfolio {
    var id: UUID
    var clientName: String
    var stocks: [Stock]
    var createdDate: Date
    
    init(clientName: String) {
        self.id = UUID()
        self.clientName = clientName
        self.stocks = []
        self.createdDate = Date()
    }
    
    // Java equivalent: calculatePortfolioValue
    func totalValue() -> Double {
        stocks.reduce(0) { $0 + $1.currentValue }
    }
    
    // Java equivalent: getComposition
    func composition() -> [String: Int] {
        var comp: [String: Int] = [:]
        for stock in stocks {
            comp[stock.tickerSymbol] = stock.totalShares
        }
        return comp
    }
    
    // Java equivalent: getValueDistribution
    func valueDistribution() -> [String: Double] {
        var dist: [String: Double] = [:]
        for stock in stocks {
            dist[stock.tickerSymbol] = stock.currentValue
        }
        return dist
    }
    
    func addStock(_ stock: Stock) {
        stocks.append(stock)
    }
    
    func removeStock(_ stock: Stock) {
        stocks.removeAll { $0.id == stock.id }
    }
}
