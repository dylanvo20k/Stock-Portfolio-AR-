import SwiftUI

struct StockInfoCard: View {
    let stock: Stock
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.tickerSymbol)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(stock.companyName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(stock.currentPrice, format: .currency(code: "USD"))
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 4) {
                        Image(systemName: stock.gainLossPercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(stock.gainLossPercent, format: .percent.precision(.fractionLength(2)))
                    }
                    .font(.caption)
                    .foregroundStyle(stock.gainLossPercent >= 0 ? .green : .red)
                }
            }
            
            Divider()
            
            HStack {
                InfoItem(label: "Shares", value: "\(stock.totalShares)")
                Spacer()
                InfoItem(label: "Value", value: stock.currentValue.formatted(.currency(code: "USD")))
                Spacer()
                InfoItem(label: "Avg Cost", value: stock.averagePurchasePrice.formatted(.currency(code: "USD")))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding()
    }
}

struct InfoItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}
