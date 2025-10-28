import SwiftUI
import SwiftData

struct PortfolioListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var portfolios: [Portfolio]
    @State private var showingAddStock = false
    @State private var showingARView = false
    @State private var showingDashboard = false
    
    private var portfolio: Portfolio? {
        portfolios.first
    }
    
    private var stocks: [Stock] {
        portfolio?.stocks ?? []
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Portfolio summary card
                portfolioSummaryCard
                
                // Stock list
                List {
                    ForEach(stocks) { stock in
                        NavigationLink(destination: StockDetailView(stock: stock)) {
                            StockRow(stock: stock)
                        }
                    }
                    .onDelete(perform: deleteStocks)
                }
                .refreshable {
                    await refreshPrices()
                }
            }
            .navigationTitle(portfolio?.clientName ?? "Portfolio")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Add Stock", systemImage: "plus") {
                            showingAddStock = true
                        }
                        
                        Button("Dashboard", systemImage: "chart.bar.fill") {
                            showingDashboard = true
                        }
                        
                        Button("View in AR", systemImage: "arkit") {
                            showingARView = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddStock) {
                AddStockView(modelContext: modelContext, portfolio: portfolio)
            }
            .sheet(isPresented: $showingDashboard) {
                NavigationStack {
                    PortfolioDashboardView(stocks: stocks)
                        .navigationTitle("Dashboard")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showingDashboard = false
                                }
                            }
                        }
                }
            }
            .fullScreenCover(isPresented: $showingARView) {
                ARPortfolioView(stocks: stocks)
            }
        }
    }
    
    private var portfolioSummaryCard: some View {
        VStack(spacing: 12) {
            Text("Total Value")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(calculatePortfolioValue(), format: .currency(code: "USD"))
                .font(.system(size: 36, weight: .bold))
            
            HStack(spacing: 20) {
                VStack {
                    Text("Stocks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(stocks.count)")
                        .font(.headline)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack {
                    Text("Total Gain/Loss")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    let totalGainLoss = calculateTotalGainLoss()
                    Text(totalGainLoss, format: .currency(code: "USD"))
                        .font(.headline)
                        .foregroundStyle(totalGainLoss >= 0 ? .green : .red)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack {
                    Text("Last Updated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(stocks.first?.lastUpdated ?? Date(), style: .time)
                        .font(.headline)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }
    
    private func calculatePortfolioValue() -> Double {
        portfolio?.totalValue() ?? 0
    }
    
    private func calculateTotalGainLoss() -> Double {
        let currentValue = stocks.reduce(0) { $0 + $1.currentValue }
        let totalCost = stocks.reduce(0) { $0 + (Double($1.totalShares) * $1.averagePurchasePrice) }
        return currentValue - totalCost
    }
    
    private func deleteStocks(at offsets: IndexSet) {
        for index in offsets {
            let stock = stocks[index]
            
            // Delete all transactions
            for transaction in stock.transactions {
                modelContext.delete(transaction)
            }
            
            // Remove from portfolio
            portfolio?.removeStock(stock)
            
            // Delete stock
            modelContext.delete(stock)
        }
        
        try? modelContext.save()
    }
    
    private func refreshPrices() async {
        let apiService = StockAPIService()
        
        for stock in stocks {
            do {
                let price = try await apiService.fetchCurrentPrice(symbol: stock.tickerSymbol)
                stock.currentPrice = price
                stock.lastUpdated = Date()
            } catch {
                print("Failed to refresh \(stock.tickerSymbol): \(error)")
            }
        }
        
        try? modelContext.save()
    }
}

struct StockRow: View {
    let stock: Stock
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(stock.tickerSymbol)
                    .font(.headline)
                Text("\(stock.totalShares) shares")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(stock.currentValue, format: .currency(code: "USD"))
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Image(systemName: stock.gainLossPercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(stock.gainLossPercent, format: .percent.precision(.fractionLength(2)))
                }
                .font(.caption)
                .foregroundStyle(stock.gainLossPercent >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}
