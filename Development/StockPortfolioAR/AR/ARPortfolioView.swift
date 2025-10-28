import SwiftUI
import RealityKit
import ARKit

struct ARPortfolioView: View {
    let stocks: [Stock]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var arViewModel = ARViewModel()
    
    var body: some View {
        ZStack {
            // AR View
            ARViewContainer(stocks: stocks, viewModel: arViewModel)
                .ignoresSafeArea()
            
            // UI Overlay
            VStack {
                // Top Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    
                    Spacer()
                    
                    Text("AR Portfolio")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Button {
                        arViewModel.resetView()
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                }
                .padding()
                
                Spacer()
                
                // Floating Chart Panel
                if arViewModel.showingChart, let selectedStock = arViewModel.selectedStock {
                    FloatingChartPanel(stock: selectedStock, viewModel: arViewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: arViewModel.showingChart)
                } else if let selectedStock = arViewModel.selectedStock, !arViewModel.showingChart {
                    // Quick info card when chart is hidden
                    StockInfoCard(stock: selectedStock)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if !arViewModel.isPlacementReady {
                    Text("Move your phone to find a surface")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            arViewModel.setupAR(with: stocks)
        }
    }
}

struct FloatingChartPanel: View {
    let stock: Stock
    @ObservedObject var viewModel: ARViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
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
                
                Button {
                    viewModel.dismissStock()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Chart
            StockChartView(stock: stock)
                .frame(height: 320)
                .background(.ultraThinMaterial)
            
            // Quick stats
            HStack(spacing: 20) {
                StatColumn(
                    label: "Current",
                    value: stock.currentPrice.formatted(.currency(code: "USD")),
                    color: .blue
                )
                
                StatColumn(
                    label: "Shares",
                    value: "\(stock.totalShares)",
                    color: .purple
                )
                
                StatColumn(
                    label: "Value",
                    value: stock.currentValue.formatted(.currency(code: "USD")),
                    color: .green
                )
                
                StatColumn(
                    label: "Gain/Loss",
                    value: stock.gainLossPercent.formatted(.percent.precision(.fractionLength(1))),
                    color: stock.gainLossPercent >= 0 ? .green : .red
                )
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 10)
        .padding()
    }
}

struct StatColumn: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}
