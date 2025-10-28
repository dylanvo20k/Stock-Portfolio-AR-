//
//  Stock 2.swift
//  StockPortfolioAR
//
//  Created by Dylan Vo on 10/28/25.
//


import Foundation
import SwiftData

@Model
class Stock {
    var id: UUID
    var tickerSymbol: String
    var companyName: String
    var transactions: [Transaction]
    var currentPrice: Double
    var lastUpdated: Date
    
    init(tickerSymbol: String, companyName: String) {
        self.id = UUID()
        self.tickerSymbol = tickerSymbol
        self.companyName = companyName
        self.transactions = []
        self.currentPrice = 0.0
        self.lastUpdated = Date()
    }
    
    // Computed properties (like your Java methods)
    var totalShares: Int {
        transactions.reduce(0) { $0 + $1.shares }
    }
    
    var averagePurchasePrice: Double {
        let totalCost = transactions.reduce(0.0) { $0 + ($1.pricePerShare * Double($1.shares)) }
        let totalShares = Double(self.totalShares)
        return totalShares > 0 ? totalCost / totalShares : 0
    }
    
    var currentValue: Double {
        currentPrice * Double(totalShares)
    }
    
    var gainLossPercent: Double {
        let avgPrice = averagePurchasePrice
        return avgPrice > 0 ? ((currentPrice - avgPrice) / avgPrice) * 100 : 0
    }
}
