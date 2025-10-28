import SwiftUI
import Foundation
import SwiftData

struct AddStockView: View {
    let modelContext: ModelContext
    let portfolio: Portfolio?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var symbol = ""
    @State private var shares = ""
    @State private var purchaseDate = Date()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchResults: [StockSearchResult] = []
    @State private var isSearching = false
    @State private var selectedStock: StockSearchResult?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Search Stock") {
                    HStack {
                        TextField("Ticker Symbol or Company Name", text: $symbol)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: symbol) { _, newValue in
                                if newValue.count >= 1 {
                                    searchStocks(query: newValue)
                                } else {
                                    searchResults = []
                                }
                            }
                        
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    if !searchResults.isEmpty {
                        ForEach(searchResults) { result in
                            Button {
                                selectStock(result)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.symbol)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(result.name)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                
                if selectedStock != nil {
                    Section("Stock Details") {
                        HStack {
                            Text("Symbol")
                            Spacer()
                            Text(symbol)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let name = selectedStock?.name {
                            HStack {
                                Text("Company")
                                Spacer()
                                Text(name)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        
                        if let price = selectedStock?.currentPrice {
                            HStack {
                                Text("Current Price")
                                Spacer()
                                Text(price, format: .currency(code: "USD"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Section("Purchase Details") {
                        TextField("Number of Shares", text: $shares)
                            .keyboardType(.numberPad)
                        
                        DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    }
                    
                    if let sharesInt = Int(shares), sharesInt > 0, let price = selectedStock?.currentPrice {
                        Section {
                            HStack {
                                Text("Estimated Total Cost")
                                Spacer()
                                Text(Double(sharesInt) * price, format: .currency(code: "USD"))
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                if selectedStock != nil {
                    Section {
                        Button {
                            addStock()
                        } label: {
                            if isLoading {
                                HStack {
                                    ProgressView()
                                    Text("Adding...")
                                }
                            } else {
                                Text("Add Stock")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .disabled(symbol.isEmpty || shares.isEmpty || isLoading)
                    }
                }
            }
            .navigationTitle("Add Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchStocks(query: String) {
        // Simple search with common stock symbols
        isSearching = true
        
        let commonStocks: [StockSearchResult] = [
            StockSearchResult(symbol: "AAPL", name: "Apple Inc.", currentPrice: nil),
            StockSearchResult(symbol: "GOOGL", name: "Alphabet Inc.", currentPrice: nil),
            StockSearchResult(symbol: "MSFT", name: "Microsoft Corporation", currentPrice: nil),
            StockSearchResult(symbol: "TSLA", name: "Tesla, Inc.", currentPrice: nil),
            StockSearchResult(symbol: "AMZN", name: "Amazon.com, Inc.", currentPrice: nil),
            StockSearchResult(symbol: "META", name: "Meta Platforms, Inc.", currentPrice: nil),
            StockSearchResult(symbol: "NVDA", name: "NVIDIA Corporation", currentPrice: nil),
            StockSearchResult(symbol: "NFLX", name: "Netflix, Inc.", currentPrice: nil),
            StockSearchResult(symbol: "AMD", name: "Advanced Micro Devices, Inc.", currentPrice: nil),
            StockSearchResult(symbol: "INTC", name: "Intel Corporation", currentPrice: nil)
        ]
        
        let filtered = commonStocks.filter {
            $0.symbol.lowercased().contains(query.lowercased()) ||
            $0.name.lowercased().contains(query.lowercased())
        }
        
        searchResults = Array(filtered.prefix(5))
        isSearching = false
        
        // Fetch current prices for results
        Task {
            await fetchPricesForResults()
        }
    }
    
    private func fetchPricesForResults() async {
        let apiService = StockAPIService()
        
        await MainActor.run {
            for i in 0..<searchResults.count {
                Task {
                    if let price = try? await apiService.fetchCurrentPrice(symbol: searchResults[i].symbol) {
                        await MainActor.run {
                            if i < searchResults.count {
                                searchResults[i].currentPrice = price
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func selectStock(_ result: StockSearchResult) {
        selectedStock = result
        symbol = result.symbol
        searchResults = []
    }
    
    private func addStock() {
        guard let sharesInt = Int(shares),
              let portfolio = portfolio else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let apiService = StockAPIService()
                let stockSymbol = symbol.uppercased()
                
                // Fetch all data
                let companyName = try await apiService.fetchCompanyName(symbol: stockSymbol)
                let historicalPrice = try await apiService.fetchPrice(symbol: stockSymbol, on: purchaseDate)
                let currentPrice = try await apiService.fetchCurrentPrice(symbol: stockSymbol)
                
                // Add to database on main thread
                await MainActor.run {
                    // Find or create stock
                    let stock = portfolio.stocks.first { $0.tickerSymbol == stockSymbol } ?? {
                        let newStock = Stock(tickerSymbol: stockSymbol, companyName: companyName)
                        modelContext.insert(newStock)
                        portfolio.addStock(newStock)
                        return newStock
                    }()
                    
                    // Add transaction
                    let transaction = Transaction(
                        shares: sharesInt,
                        pricePerShare: historicalPrice,
                        date: purchaseDate,
                        type: .buy
                    )
                    modelContext.insert(transaction)
                    stock.transactions.append(transaction)
                    
                    // Update current price
                    stock.currentPrice = currentPrice
                    stock.lastUpdated = Date()
                    
                    // Save
                    try? modelContext.save()
                    
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to add stock: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

struct StockSearchResult: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    var currentPrice: Double?
}
