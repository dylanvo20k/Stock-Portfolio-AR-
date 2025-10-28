import SwiftUI
import SwiftData

struct SellStockView: View {
    let stock: Stock
    let modelContext: ModelContext
    
    @Environment(\.dismiss) private var dismiss
    @State private var sharesToSell = ""
    @State private var saleDate = Date()
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Stock Information") {
                    HStack {
                        Text("Symbol")
                        Spacer()
                        Text(stock.tickerSymbol)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Shares Owned")
                        Spacer()
                        Text("\(stock.totalShares)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Current Price")
                        Spacer()
                        Text(stock.currentPrice, format: .currency(code: "USD"))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Sale Details") {
                    TextField("Shares to Sell", text: $sharesToSell)
                        .keyboardType(.numberPad)
                    
                    DatePicker("Sale Date", selection: $saleDate, displayedComponents: .date)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    if let shares = Int(sharesToSell), shares > 0 {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Estimated Sale Value")
                                Spacer()
                                Text(Double(shares) * stock.currentPrice, format: .currency(code: "USD"))
                                    .fontWeight(.semibold)
                            }
                            
                            let avgCost = stock.averagePurchasePrice * Double(shares)
                            let saleValue = stock.currentPrice * Double(shares)
                            let profit = saleValue - avgCost
                            
                            HStack {
                                Text("Estimated Profit/Loss")
                                Spacer()
                                Text(profit, format: .currency(code: "USD"))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(profit >= 0 ? .green : .red)
                            }
                        }
                        .font(.subheadline)
                    }
                }
                
                Section {
                    Button {
                        sellStock()
                    } label: {
                        if isLoading {
                            HStack {
                                ProgressView()
                                Text("Selling...")
                            }
                        } else {
                            Text("Sell Shares")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(sharesToSell.isEmpty || isLoading || (Int(sharesToSell) ?? 0) > stock.totalShares)
                }
            }
            .navigationTitle("Sell \(stock.tickerSymbol)")
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
    
    private func sellStock() {
        guard let shares = Int(sharesToSell), shares > 0, shares <= stock.totalShares else {
            errorMessage = "Invalid number of shares"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let apiService = StockAPIService()
                let salePrice = try await apiService.fetchPrice(symbol: stock.tickerSymbol, on: saleDate)
                
                await MainActor.run {
                    let transaction = Transaction(
                        shares: -shares,
                        pricePerShare: salePrice,
                        date: saleDate,
                        type: .sell
                    )
                    
                    modelContext.insert(transaction)
                    stock.transactions.append(transaction)
                    
                    try? modelContext.save()
                    
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to sell: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
