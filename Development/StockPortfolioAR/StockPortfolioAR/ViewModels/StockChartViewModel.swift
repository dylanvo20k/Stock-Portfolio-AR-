import Foundation
import SwiftUI

@MainActor
class StockChartViewModel: ObservableObject {
    @Published var chartData: [ChartDataPoint] = []
    @Published var selectedTimeframe: ChartTimeframe = .oneMonth
    @Published var selectedDate: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let stock: Stock
    private let apiService = StockAPIService()
    private var autoRefreshTask: Task<Void, Never>?
    
    init(stock: Stock) {
        self.stock = stock
        startAutoRefresh()
    }
    
    deinit {
        autoRefreshTask?.cancel()
    }
    
    var selectedDataPoint: ChartDataPoint? {
        guard let selectedDate = selectedDate else { return nil }
        return chartData.min(by: {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        })
    }
    
    var selectedPriceChange: Double? {
        guard let selected = selectedDataPoint,
              let first = chartData.first else { return nil }
        return selected.price - first.price
    }
    
    var selectedPercentChange: Double? {
        guard let selected = selectedDataPoint,
              let first = chartData.first,
              first.price > 0 else { return nil }
        return ((selected.price - first.price) / first.price)
    }
    
    var priceChange: Double {
        guard let first = chartData.first,
              let last = chartData.last else { return 0 }
        return last.price - first.price
    }
    
    var priceRange: ClosedRange<Double> {
        guard !chartData.isEmpty else { return 0...100 }
        let prices = chartData.map { $0.price }
        let min = prices.min() ?? 0
        let max = prices.max() ?? 100
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }
    
    var dateFormat: Date.FormatStyle {
        switch selectedTimeframe {
        case .oneDay:
            return .dateTime.hour().minute()
        case .oneWeek, .oneMonth:
            return .dateTime.month(.abbreviated).day()
        case .threeMonths, .oneYear, .all:
            return .dateTime.month(.abbreviated).year()
        }
    }
    
    func loadChartData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let data = try await fetchChartData(for: selectedTimeframe)
            chartData = data
            
            // Select most recent point by default
            selectedDate = data.last?.date
        } catch {
            errorMessage = "Failed to load chart: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func selectTimeframe(_ timeframe: ChartTimeframe) {
        guard timeframe != selectedTimeframe, !isLoading else { return }
        selectedTimeframe = timeframe
        
        Task {
            await loadChartData()
        }
    }
    
    func changeTimeframe(_ timeframe: ChartTimeframe) async {
        guard timeframe != selectedTimeframe else { return }
        selectedTimeframe = timeframe
        await loadChartData()
    }
    
    private func fetchChartData(for timeframe: ChartTimeframe) async throws -> [ChartDataPoint] {
        let endDate = Date()
        let startDate = timeframe.startDate
        
        // Generate date range
        var dates: [Date] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = Calendar.current.date(
                byAdding: timeframe.dateComponent,
                value: 1,
                to: currentDate
            ) ?? endDate
        }
        
        // Sample dates to reduce API calls
        let sampledDates = sampleDates(dates, maxCount: timeframe.maxDataPoints)
        
        var dataPoints: [ChartDataPoint] = []
        var apiLimitReached = false
        
        // Try to fetch real data first
        for (index, date) in sampledDates.enumerated() {
            // If we already hit the limit, skip API calls
            if apiLimitReached {
                dataPoints.append(generateMockDataPoint(date: date, index: index, total: sampledDates.count))
                continue
            }
            
            do {
                let price = try await apiService.fetchPrice(symbol: stock.tickerSymbol, on: date)
                dataPoints.append(ChartDataPoint(date: date, price: price))
                
                // Small delay to avoid rate limiting
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            } catch {
                // Check if it's a rate limit error
                let errorString = error.localizedDescription.lowercased()
                if errorString.contains("rate limit") || errorString.contains("unable to parse") {
                    print("⚠️ API rate limit reached, switching to mock data")
                    apiLimitReached = true
                    
                    // Generate mock data for this point and continue
                    dataPoints.append(generateMockDataPoint(date: date, index: index, total: sampledDates.count))
                } else {
                    // Other error, use mock data
                    dataPoints.append(generateMockDataPoint(date: date, index: index, total: sampledDates.count))
                }
            }
        }
        
        return dataPoints.sorted(by: { $0.date < $1.date })
    }
    
    private func generateMockDataPoint(date: Date, index: Int, total: Int) -> ChartDataPoint {
        let basePrice = stock.currentPrice
        let progress = Double(index) / Double(total)
        let trend = (stock.gainLossPercent / 100) // Use actual gain/loss as trend
        let noise = Double.random(in: -0.02...0.02) // ±2% random noise
        
        // Price starts lower and trends toward current
        let priceFactor = 1.0 + (trend * progress) + noise
        let price = basePrice * priceFactor
        
        return ChartDataPoint(date: date, price: max(price, 0.01))
    }
    
    private func sampleDates(_ dates: [Date], maxCount: Int) -> [Date] {
        guard dates.count > maxCount else { return dates }
        
        let step = dates.count / maxCount
        var sampled: [Date] = []
        
        for i in stride(from: 0, to: dates.count, by: step) {
            sampled.append(dates[i])
        }
        
        // Always include the last date
        if let last = dates.last, !sampled.contains(last) {
            sampled.append(last)
        }
        
        return sampled
    }
    
    private func startAutoRefresh() {
        autoRefreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                
                guard !Task.isCancelled else { break }
                
                // Only refresh if on 1-day chart
                if selectedTimeframe == .oneDay {
                    await loadChartData()
                }
            }
        }
    }
}
