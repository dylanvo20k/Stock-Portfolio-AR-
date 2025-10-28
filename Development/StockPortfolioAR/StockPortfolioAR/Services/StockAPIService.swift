import Foundation

class StockAPIService {
    private let apiKey = "" // Get a free API key from Alpha Vantage!
    private let baseURL = "https://www.alphavantage.co/query"
    
    func fetchCurrentPrice(symbol: String) async throws -> Double {
        let urlString = "\(baseURL)?function=GLOBAL_QUOTE&symbol=\(symbol)&apikey=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Debug
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Alpha Vantage Response: \(jsonString)")
        }
        
        let response = try JSONDecoder().decode(AlphaVantageQuoteResponse.self, from: data)
        
        guard let priceString = response.globalQuote.price,
              let price = Double(priceString) else {
            throw APIError.noPriceData
        }
        
        return price
    }
    
    func fetchCompanyName(symbol: String) async throws -> String {
        let urlString = "\(baseURL)?function=OVERVIEW&symbol=\(symbol)&apikey=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let response = try JSONDecoder().decode(AlphaVantageOverviewResponse.self, from: data)
        
        // Return name or symbol if not available
        return response.name ?? symbol
    }
    
    func fetchPrice(symbol: String, on date: Date) async throws -> Double {
        // Alpha Vantage requires YYYY-MM-DD format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let urlString = "\(baseURL)?function=TIME_SERIES_DAILY&symbol=\(symbol)&apikey=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let response = try JSONDecoder().decode(AlphaVantageTimeSeriesResponse.self, from: data)
        
        // Try to find the exact date
        if let dayData = response.timeSeries[dateString],
           let closeString = dayData.close,
           let price = Double(closeString) {
            return price
        }
        
        // If exact date not found, find closest date
        let calendar = Calendar.current
        for offset in 0...10 {
            let checkDate = calendar.date(byAdding: .day, value: -offset, to: date)!
            let checkDateString = dateFormatter.string(from: checkDate)
            
            if let dayData = response.timeSeries[checkDateString],
               let closeString = dayData.close,
               let price = Double(closeString) {
                print("Using price from \(checkDateString) instead of \(dateString)")
                return price
            }
        }
        
        // If no historical data found, use current price
        print("No historical data found, using current price")
        return try await fetchCurrentPrice(symbol: symbol)
    }
}

// MARK: - Alpha Vantage Response Models

struct AlphaVantageQuoteResponse: Codable {
    let globalQuote: GlobalQuote
    
    enum CodingKeys: String, CodingKey {
        case globalQuote = "Global Quote"
    }
    
    struct GlobalQuote: Codable {
        let symbol: String?
        let price: String?
        
        enum CodingKeys: String, CodingKey {
            case symbol = "01. symbol"
            case price = "05. price"
        }
    }
}

struct AlphaVantageOverviewResponse: Codable {
    let symbol: String?
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case symbol = "Symbol"
        case name = "Name"
    }
}

struct AlphaVantageTimeSeriesResponse: Codable {
    let timeSeries: [String: DayData]
    
    enum CodingKeys: String, CodingKey {
        case timeSeries = "Time Series (Daily)"
    }
    
    struct DayData: Codable {
        let open: String?
        let high: String?
        let low: String?
        let close: String?
        let volume: String?
        
        enum CodingKeys: String, CodingKey {
            case open = "1. open"
            case high = "2. high"
            case low = "3. low"
            case close = "4. close"
            case volume = "5. volume"
        }
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidData
    case noPriceData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidData: return "Unable to parse response"
        case .noPriceData: return "No price data available for this symbol"
        }
    }
}
