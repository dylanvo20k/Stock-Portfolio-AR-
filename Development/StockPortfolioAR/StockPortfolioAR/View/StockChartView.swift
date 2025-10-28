import SwiftUI
import Charts

struct StockChartView: View {
    let stock: Stock
    @StateObject private var viewModel: StockChartViewModel
    
    init(stock: Stock) {
        self.stock = stock
        _viewModel = StateObject(wrappedValue: StockChartViewModel(stock: stock))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Timeframe selector
            timeframeSelector
            
            // Chart
            if viewModel.isLoading {
                chartLoadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else {
                interactiveChart
            }
            
            // Selected price info
            if let selected = viewModel.selectedDataPoint {
                selectedPriceCard(selected)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .task {
            await viewModel.loadChartData()
        }
    }
    
    private var timeframeSelector: some View {
        HStack(spacing: 12) {
            ForEach(ChartTimeframe.allCases, id: \.self) { timeframe in
                Button {
                    viewModel.selectTimeframe(timeframe)
                } label: {
                    Text(timeframe.rawValue)
                        .font(.subheadline)
                        .fontWeight(viewModel.selectedTimeframe == timeframe ? .bold : .regular)
                        .foregroundStyle(viewModel.selectedTimeframe == timeframe ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            viewModel.selectedTimeframe == timeframe ? Color.blue : Color.gray.opacity(0.2)
                        )
                        .clipShape(Capsule())
                }
                .disabled(viewModel.isLoading)
            }
        }
    }
    
    private var interactiveChart: some View {
        Chart(viewModel.chartData) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Price", dataPoint.price)
            )
            .foregroundStyle(chartColor)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Date", dataPoint.date),
                y: .value("Price", dataPoint.price)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [chartColor.opacity(0.3), chartColor.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
            
            // Selection indicator
            if let selected = viewModel.selectedDataPoint,
               selected.date == dataPoint.date {
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Price", dataPoint.price)
                )
                .foregroundStyle(chartColor)
                .symbolSize(100)
                
                RuleMark(
                    x: .value("Date", dataPoint.date)
                )
                .foregroundStyle(chartColor.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
        }
        .frame(height: 300)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel(format: viewModel.dateFormat)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let price = value.as(Double.self) {
                        Text(price, format: .currency(code: "USD"))
                    }
                }
            }
        }
        .chartYScale(domain: viewModel.priceRange)
        .chartXSelection(value: $viewModel.selectedDate)
    }
    
    private var chartColor: Color {
        viewModel.priceChange >= 0 ? .green : .red
    }
    
    private var chartLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading chart data...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 300)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await viewModel.loadChartData()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(height: 300)
    }
    
    private func selectedPriceCard(_ dataPoint: ChartDataPoint) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dataPoint.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(dataPoint.price, format: .currency(code: "USD"))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            if let change = viewModel.selectedPriceChange {
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(abs(change), format: .currency(code: "USD"))
                    }
                    .font(.headline)
                    .foregroundStyle(change >= 0 ? .green : .red)
                    
                    if let percentChange = viewModel.selectedPercentChange {
                        Text(percentChange, format: .percent.precision(.fractionLength(2)))
                            .font(.caption)
                            .foregroundStyle(percentChange >= 0 ? .green : .red)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
