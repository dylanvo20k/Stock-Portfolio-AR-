import SwiftUI
import SwiftData

struct StockDetailView: View {
    let stock: Stock
    @Environment(\.modelContext) private var modelContext
    @State private var showingSellSheet = false
    
    var body: some View {
        List {
            Section {
                StockChartView(stock: stock)
                    .listRowInsets(EdgeInsets())
            }
            
            Section("Overview") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(stock.companyName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(stock.tickerSymbol)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Current Price")
                    Spacer()
                    Text(stock.currentPrice, format: .currency(code: "USD"))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Total Shares")
                    Spacer()
                    Text("\(stock.totalShares)")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Current Value")
                    Spacer()
                    Text(stock.currentValue, format: .currency(code: "USD"))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Avg Purchase Price")
                    Spacer()
                    Text(stock.averagePurchasePrice, format: .currency(code: "USD"))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Gain/Loss")
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: stock.gainLossPercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(stock.gainLossPercent, format: .percent.precision(.fractionLength(2)))
                    }
                    .foregroundStyle(stock.gainLossPercent >= 0 ? .green : .red)
                    .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Total Gain/Loss")
                    Spacer()
                    let gainLoss = stock.currentValue - (stock.averagePurchasePrice * Double(stock.totalShares))
                    Text(gainLoss, format: .currency(code: "USD"))
                        .foregroundStyle(gainLoss >= 0 ? .green : .red)
                        .fontWeight(.semibold)
                }
            }
            
            Section {
                Button {
                    showingSellSheet = true
                } label: {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                        Text("Sell Shares")
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                }
                .disabled(stock.totalShares == 0)
            }
            
            Section("Transaction History") {
                if stock.transactions.isEmpty {
                    Text("No transactions yet")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(stock.transactions.sorted(by: { $0.date > $1.date }), id: \.id) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                    .onDelete { indexSet in
                        deleteTransactions(at: indexSet)
                    }
                }
            }
            
            Section {
                HStack {
                    Text("Last Updated")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(stock.lastUpdated, style: .relative)
                }
                .font(.caption)
            }
        }
        .navigationTitle(stock.tickerSymbol)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSellSheet) {
            SellStockView(stock: stock, modelContext: modelContext)
        }
    }
    
    private func deleteTransactions(at offsets: IndexSet) {
        let sortedTransactions = stock.transactions.sorted(by: { $0.date > $1.date })
        
        for index in offsets {
            let transaction = sortedTransactions[index]
            if let idx = stock.transactions.firstIndex(where: { $0.id == transaction.id }) {
                stock.transactions.remove(at: idx)
                modelContext.delete(transaction)
            }
        }
        
        try? modelContext.save()
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type == .buy ? "BUY" : "SELL")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(transaction.type == .buy ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(transaction.type == .buy ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    )
                
                Text(transaction.date, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(abs(transaction.shares)) shares")
                    .font(.headline)
                
                Text(transaction.pricePerShare, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(Double(abs(transaction.shares)) * transaction.pricePerShare, format: .currency(code: "USD"))
                    .font(.caption)
                    .foregroundStyle(transaction.type == .buy ? .red : .green)
            }
        }
        .padding(.vertical, 4)
    }
}
