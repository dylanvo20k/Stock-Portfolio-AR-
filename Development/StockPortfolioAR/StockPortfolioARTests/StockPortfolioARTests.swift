import XCTest
@testable import StockPortfolioAR

// MARK: - Stock Tests (Pure Logic - No SwiftData)

final class StockCalculationTests: XCTestCase {
    
    func testTotalSharesCalculation() {
        let stock = Stock(tickerSymbol: "AAPL", companyName: "Apple Inc.")
        
        // Test with no transactions
        XCTAssertEqual(stock.totalShares, 0, "Total shares should be 0 with no transactions")
        
        // Add one buy transaction
        let buy = Transaction(shares: 10, pricePerShare: 100.0, date: Date(), type: .buy)
        stock.transactions.append(buy)
        
        XCTAssertEqual(stock.totalShares, 10, "Total shares should be 10 after buying 10")
        
        // Add a sell transaction
        let sell = Transaction(shares: -3, pricePerShare: 120.0, date: Date(), type: .sell)
        stock.transactions.append(sell)
        
        XCTAssertEqual(stock.totalShares, 7, "Total shares should be 7 after selling 3")
    }
    
    func testAveragePurchasePriceCalculation() {
        let stock = Stock(tickerSymbol: "AAPL", companyName: "Apple Inc.")
        
        // Buy 10 shares at $100 = $1,000
        let buy1 = Transaction(shares: 10, pricePerShare: 100.0, date: Date(), type: .buy)
        stock.transactions.append(buy1)
        
        XCTAssertEqual(stock.averagePurchasePrice, 100.0, accuracy: 0.01)
        
        // Buy 5 more shares at $120 = $600
        // Total: 15 shares, $1,600 spent
        // Average: $1,600 / 15 = $106.67
        let buy2 = Transaction(shares: 5, pricePerShare: 120.0, date: Date(), type: .buy)
        stock.transactions.append(buy2)
        
        XCTAssertEqual(stock.averagePurchasePrice, 106.67, accuracy: 0.01)
    }
    
    func testCurrentValueCalculation() {
        let stock = Stock(tickerSymbol: "AAPL", companyName: "Apple Inc.")
        stock.currentPrice = 150.0
        
        let transaction = Transaction(shares: 10, pricePerShare: 100.0, date: Date(), type: .buy)
        stock.transactions.append(transaction)
        
        // 10 shares * $150 = $1,500
        XCTAssertEqual(stock.currentValue, 1500.0, "Current value should be shares * current price")
    }
    
    func testGainLossPercentCalculation() {
        let stock = Stock(tickerSymbol: "AAPL", companyName: "Apple Inc.")
        
        // Bought at $100, now worth $150 = 50% gain
        stock.currentPrice = 150.0
        let transaction = Transaction(shares: 10, pricePerShare: 100.0, date: Date(), type: .buy)
        stock.transactions.append(transaction)
        
        XCTAssertEqual(stock.gainLossPercent, 50.0, accuracy: 0.01, "Should show 50% gain")
    }
    
    func testGainLossWithLoss() {
        let stock = Stock(tickerSymbol: "AAPL", companyName: "Apple Inc.")
        
        // Bought at $100, now worth $80 = -20% loss
        stock.currentPrice = 80.0
        let transaction = Transaction(shares: 10, pricePerShare: 100.0, date: Date(), type: .buy)
        stock.transactions.append(transaction)
        
        XCTAssertEqual(stock.gainLossPercent, -20.0, accuracy: 0.01, "Should show 20% loss")
    }
}

// MARK: - Portfolio Tests (Pure Logic)

final class PortfolioCalculationTests: XCTestCase {
    
    func testPortfolioTotalValue() {
        let portfolio = Portfolio(clientName: "Test")
        
        // Empty portfolio
        XCTAssertEqual(portfolio.totalValue(), 0.0, "Empty portfolio should have $0 value")
        
        // Add first stock: 10 shares at $150 = $1,500
        let stock1 = Stock(tickerSymbol: "AAPL", companyName: "Apple Inc.")
        stock1.currentPrice = 150.0
        let trans1 = Transaction(shares: 10, pricePerShare: 100.0, date: Date(), type: .buy)
        stock1.transactions.append(trans1)
        portfolio.addStock(stock1)
        
        XCTAssertEqual(portfolio.totalValue(), 1500.0, "Portfolio with one stock should be $1,500")
        
        // Add second stock: 5 shares at $2,800 = $14,000
        let stock2 = Stock(tickerSymbol: "GOOGL", companyName: "Alphabet")
        stock2.currentPrice = 2800.0
        let trans2 = Transaction(shares: 5, pricePerShare: 2500.0, date: Date(), type: .buy)
        stock2.transactions.append(trans2)
        portfolio.addStock(stock2)
        
        // Total: $1,500 + $14,000 = $15,500
        XCTAssertEqual(portfolio.totalValue(), 15500.0, "Portfolio should be $15,500")
    }
    
    func testPortfolioComposition() {
        let portfolio = Portfolio(clientName: "Test")
        
        let stock1 = Stock(tickerSymbol: "AAPL", companyName: "Apple")
        let trans1 = Transaction(shares: 10, pricePerShare: 100.0, date: Date(), type: .buy)
        stock1.transactions.append(trans1)
        
        let stock2 = Stock(tickerSymbol: "GOOGL", companyName: "Alphabet")
        let trans2 = Transaction(shares: 5, pricePerShare: 2500.0, date: Date(), type: .buy)
        stock2.transactions.append(trans2)
        
        portfolio.addStock(stock1)
        portfolio.addStock(stock2)
        
        let composition = portfolio.composition()
        
        XCTAssertEqual(composition["AAPL"], 10, "Should have 10 AAPL shares")
        XCTAssertEqual(composition["GOOGL"], 5, "Should have 5 GOOGL shares")
    }
    
    func testPortfolioValueDistribution() {
        let portfolio = Portfolio(clientName: "Test")
        
        let stock = Stock(tickerSymbol: "AAPL", companyName: "Apple")
        stock.currentPrice = 150.0
        let trans = Transaction(shares: 10, pricePerShare: 100.0, date: Date(), type: .buy)
        stock.transactions.append(trans)
        
        portfolio.addStock(stock)
        
        let distribution = portfolio.valueDistribution()
        
        XCTAssertEqual(distribution["AAPL"], 1500.0, "AAPL value should be $1,500")
    }
}

// MARK: - Transaction Tests

final class TransactionLogicTests: XCTestCase {
    
    func testTransactionCreation() {
        let date = Date()
        let transaction = Transaction(shares: 10, pricePerShare: 100.0, date: date, type: .buy)
        
        XCTAssertEqual(transaction.shares, 10)
        XCTAssertEqual(transaction.pricePerShare, 100.0)
        XCTAssertEqual(transaction.type, .buy)
        XCTAssertNotNil(transaction.id)
    }
    
    func testBuyVsSellTransactions() {
        let buy = Transaction(shares: 10, pricePerShare: 100.0, date: Date(), type: .buy)
        let sell = Transaction(shares: -5, pricePerShare: 120.0, date: Date(), type: .sell)
        
        XCTAssertEqual(buy.type, .buy)
        XCTAssertEqual(sell.type, .sell)
        XCTAssertTrue(buy.shares > 0, "Buy transactions should have positive shares")
        XCTAssertTrue(sell.shares < 0, "Sell transactions should have negative shares")
    }
}

// MARK: - Edge Cases

final class EdgeCaseTests: XCTestCase {
    
    func testZeroPrice() {
        let stock = Stock(tickerSymbol: "ZERO", companyName: "Zero Co")
        stock.currentPrice = 0.0
        let trans = Transaction(shares: 10, pricePerShare: 100.0, date: Date(), type: .buy)
        stock.transactions.append(trans)
        
        XCTAssertEqual(stock.currentValue, 0.0, "Stock with $0 price should have $0 value")
        XCTAssertEqual(stock.gainLossPercent, -100.0, "Should show 100% loss")
    }
    
    func testEmptyPortfolio() {
        let portfolio = Portfolio(clientName: "Empty")
        
        XCTAssertEqual(portfolio.totalValue(), 0.0)
        XCTAssertTrue(portfolio.composition().isEmpty)
        XCTAssertTrue(portfolio.valueDistribution().isEmpty)
    }
    
    func testOversoldStock() {
        let stock = Stock(tickerSymbol: "TEST", companyName: "Test")
        let sell = Transaction(shares: -10, pricePerShare: 100.0, date: Date(), type: .sell)
        stock.transactions.append(sell)
        
        XCTAssertEqual(stock.totalShares, -10, "Should allow negative shares (oversold)")
    }
}

// MARK: - API Error Tests

final class APIErrorTests: XCTestCase {
    
    func testErrorDescriptions() {
        XCTAssertEqual(APIError.invalidURL.errorDescription, "Invalid URL")
        XCTAssertEqual(APIError.invalidData.errorDescription, "Unable to parse response")
        XCTAssertEqual(APIError.noPriceData.errorDescription, "No price data available")
    }
}
