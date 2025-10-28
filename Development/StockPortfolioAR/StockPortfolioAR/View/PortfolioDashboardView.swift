import SwiftUI

struct PortfolioDashboardView: View {
    let stocks: [Stock]
    
    private var totalValue: Double {
        stocks.reduce(0) { $0 + $1.currentValue }
    }
    
    private var totalCost: Double {
        stocks.reduce(0) { $0 + (Double($1.totalShares) * $1.averagePurchasePrice) }
    }
    
    private var totalGainLoss: Double {
        totalValue - totalCost
    }
    
    private var totalGainLossPercent: Double {
        totalCost > 0 ? ((totalValue - totalCost) / totalCost) * 100 : 0
    }
    
    private var bestPerformer: Stock? {
        stocks.max(by: { $0.gainLossPercent < $1.gainLossPercent })
    }
    
    private var worstPerformer: Stock? {
        stocks.min(by: { $0.gainLossPercent < $1.gainLossPercent })
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Total Portfolio Value
                totalValueCard
                
                // Gain/Loss Summary
                gainLossCard
                
                // Performance Leaders
                if !stocks.isEmpty {
                    performanceCard
                }
                
                // Diversification
                if stocks.count > 1 {
                    diversificationCard
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var totalValueCard: some View {
        VStack(spacing: 12) {
            Text("Total Portfolio Value")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(totalValue, format: .currency(code: "USD"))
                .font(.system(size: 42, weight: .bold))
            
            HStack(spacing: 4) {
                Image(systemName: totalGainLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                Text(totalGainLoss, format: .currency(code: "USD"))
                Text("(\(totalGainLossPercent, format: .number.precision(.fractionLength(2)))%)")
            }
            .font(.headline)
            .foregroundStyle(totalGainLoss >= 0 ? .green : .red)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var gainLossCard: some View {
        VStack(spacing: 16) {
            Text("Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                StatItem(
                    label: "Total Cost",
                    value: totalCost.formatted(.currency(code: "USD")),
                    color: .blue
                )
                
                Spacer()
                
                StatItem(
                    label: "Total Stocks",
                    value: "\(stocks.count)",
                    color: .purple
                )
                
                Spacer()
                
                StatItem(
                    label: "Total Shares",
                    value: "\(stocks.reduce(0) { $0 + $1.totalShares })",
                    color: .orange
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var performanceCard: some View {
        VStack(spacing: 16) {
            Text("Performance Leaders")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let best = bestPerformer {
                PerformerRow(
                    title: "Best Performer",
                    stock: best,
                    color: .green
                )
            }
            
            if let worst = worstPerformer {
                PerformerRow(
                    title: "Worst Performer",
                    stock: worst,
                    color: .red
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var diversificationCard: some View {
        VStack(spacing: 16) {
            Text("Diversification")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(stocks.sorted(by: { $0.currentValue > $1.currentValue }), id: \.id) { stock in
                let percentage = (stock.currentValue / totalValue) * 100
                
                HStack {
                    Text(stock.tickerSymbol)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(percentage, format: .number.precision(.fractionLength(1)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * (percentage / 100))
                    }
                }
                .frame(height: 8)
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
        }
    }
}

struct PerformerRow: View {
    let title: String
    let stock: Stock
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(stock.tickerSymbol)
                    .font(.headline)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: stock.gainLossPercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(stock.gainLossPercent, format: .percent.precision(.fractionLength(2)))
                }
                .font(.headline)
                .foregroundStyle(color)
                
                Text(stock.currentValue, format: .currency(code: "USD"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
