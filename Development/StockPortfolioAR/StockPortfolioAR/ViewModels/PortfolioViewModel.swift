import Foundation
import SwiftData
import SwiftUI

class PortfolioViewModel: ObservableObject {
    @Published var portfolio: Portfolio?
    @Published var stocks: [Stock] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = StockAPIService()
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadPortfolio()
    }
    
    func createPortfolio(clientName: String) {
        let newPortfolio = Portfolio(clientName: clientName)
        modelContext.insert(newPortfolio)
        self.portfolio = newPortfolio
        try? modelContext.save()
    }
    
    func addStock(symbol: String, shares: Int, purchaseDate: Date) async {
        await MainActor.run {
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            let companyName = try await apiService.fetchCompanyName(symbol: symbol)
            let price = try await apiService.fetchPrice(symbol: symbol, on: purchaseDate)
            
            await MainActor.run {
                let stock = stocks.first { $0.tickerSymbol == symbol } ?? {
                    let newStock = Stock(tickerSymbol: symbol, companyName: companyName)
                    modelContext.insert(newStock)
                    stocks.append(newStock)
                    portfolio?.addStock(newStock)
                    return newStock
                }()
                
                let transaction = Transaction(
                    shares: shares,
                    pricePerShare: price,
                    date: purchaseDate,
                    type: .buy
                )
                modelContext.insert(transaction)
                stock.transactions.append(transaction)
                
                try? modelContext.save()
            }
            
            // Fetch current price after saving transaction
            let currentPrice = try await apiService.fetchCurrentPrice(symbol: symbol)
            await MainActor.run {
                if let stock = stocks.first(where: { $0.tickerSymbol == symbol }) {
                    stock.currentPrice = currentPrice
                    stock.lastUpdated = Date()
                    try? modelContext.save()
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to add stock: \(error.localizedDescription)"
            }
        }
    }
    
    func sellStock(symbol: String, shares: Int, saleDate: Date) async {
        guard let stock = stocks.first(where: { $0.tickerSymbol == symbol }) else {
            await MainActor.run {
                errorMessage = "Stock not found"
            }
            return
        }
        
        guard stock.totalShares >= shares else {
            await MainActor.run {
                errorMessage = "Not enough shares to sell"
            }
            return
        }
        
        do {
            let price = try await apiService.fetchPrice(symbol: symbol, on: saleDate)
            
            await MainActor.run {
                let transaction = Transaction(
                    shares: -shares,
                    pricePerShare: price,
                    date: saleDate,
                    type: .sell
                )
                modelContext.insert(transaction)
                stock.transactions.append(transaction)
                try? modelContext.save()
            }
            
            let currentPrice = try await apiService.fetchCurrentPrice(symbol: symbol)
            await MainActor.run {
                stock.currentPrice = currentPrice
                stock.lastUpdated = Date()
                try? modelContext.save()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to sell stock: \(error.localizedDescription)"
            }
        }
    }
    
    func calculatePortfolioValue() -> Double {
        portfolio?.totalValue() ?? 0
    }
    
    func refreshPrices() async {
        await MainActor.run {
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        for stock in stocks {
            do {
                let price = try await apiService.fetchCurrentPrice(symbol: stock.tickerSymbol)
                await MainActor.run {
                    stock.currentPrice = price
                    stock.lastUpdated = Date()
                }
            } catch {
                print("Failed to refresh \(stock.tickerSymbol): \(error)")
            }
        }
        
        await MainActor.run {
            try? modelContext.save()
        }
    }
    
    private func loadPortfolio() {
        let descriptor = FetchDescriptor<Portfolio>()
        if let portfolios = try? modelContext.fetch(descriptor),
           let first = portfolios.first {
            self.portfolio = first
            self.stocks = first.stocks
        }
    }
}
