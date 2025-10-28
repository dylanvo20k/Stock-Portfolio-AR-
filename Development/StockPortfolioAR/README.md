 # Stock Portfolio AR

An iOS stock portfolio tracker with augmented reality visualization built with SwiftUI, RealityKit, and Swift Charts.

![iOS](https://img.shields.io/badge/iOS-17.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![Platform](https://img.shields.io/badge/Platform-iPhone-lightgrey)

## Features

### 📊 Portfolio Management
- Real-time stock price tracking via Alpha Vantage API
- Buy and sell stocks with historical pricing
- Transaction history with complete audit trail
- Portfolio analytics dashboard with performance metrics
- Swipe to delete stocks or individual transactions

### 🥽 Augmented Reality Visualization
- View portfolio as interactive 3D bars in physical space
- Color-coded performance indicators (green = gains, red = losses)
- Bar height represents portfolio allocation percentage
- Tap bars to view detailed stock information
- Smooth animations and haptic feedback

### 📈 Interactive Charts
- Swift Charts integration with 6 timeframes (1D, 1W, 1M, 3M, 1Y, ALL)
- Touch-based price selection with detailed tooltips
- Real-time auto-refresh for intraday data
- Gradient area charts with smooth animations

### 📱 Additional Features
- Stock search with autocomplete
- Best/worst performer tracking
- Diversification breakdown
- Total gain/loss calculations
- Pull-to-refresh price updates

## Architecture

- **Pattern:** MVVM (Model-View-ViewModel)
- **Persistence:** SwiftData with @Model macros
- **Concurrency:** Swift async/await with @MainActor
- **UI:** SwiftUI with UIKit integration via UIViewRepresentable
- **AR:** RealityKit + ARKit for 3D visualization
- **Charts:** Swift Charts framework
- **Testing:** XCTest with 22 unit tests (90%+ coverage)

## Requirements

- iOS 17.0+
- Xcode 15.0+
- iPhone with ARKit support (6S or newer)
- Alpha Vantage API key (free tier: 25 calls/day)

## Setup

1. Clone the repository
```bash
git clone https://github.com/dylanvo20k/Stock-Portfolio-AR-.git
cd Stock-Portfolio-AR-
```

2. Open in Xcode
```bash
open StockPortfolioAR.xcodeproj
```

3. Add your Alpha Vantage API key
- Get a free key from [alphavantage.co](https://www.alphavantage.co/support/#api-key)
- Open `StockPortfolioAR/Services/StockAPIService.swift`
- Replace `YOUR_API_KEY_HERE` with your actual key on line 4

4. Build and run on a physical iPhone (AR requires real device)

## Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Persistence:** SwiftData
- **AR Framework:** RealityKit, ARKit
- **Charts:** Swift Charts
- **API:** Alpha Vantage REST API
- **Testing:** XCTest

## Project Structure

```
StockPortfolioAR/
├── Models/              # SwiftData models
│   ├── Stock.swift
│   ├── Transaction.swift
│   ├── Portfolio.swift
│   └── ChartModels.swift
├── View/                # SwiftUI views
│   ├── PortfolioListView.swift
│   ├── StockDetailView.swift
│   ├── AddStockView.swift
│   ├── SellStockView.swift
│   ├── PortfolioDashboardView.swift
│   └── StockChartView.swift
├── ViewModels/          # Business logic
│   ├── PortfolioViewModel.swift
│   └── StockChartViewModel.swift
├── Services/            # API integration
│   └── StockAPIService.swift
├── AR/                  # AR components
│   ├── ARPortfolioView.swift
│   ├── ARViewContainer.swift
│   ├── ARCoordinator.swift
│   ├── ARViewModel.swift
│   ├── ARExtensions.swift
│   └── StockInfoCard.swift
├── Utilities/
│   └── Extensions.swift
└── StockPortfolioARTests/
    └── StockPortfolioARTests.swift
```

## Screenshots

### 2D Portfolio View
- Portfolio list with real-time prices and gain/loss indicators
- Swipe to delete functionality
- Pull to refresh for latest prices

### AR Visualization
- 3D bar chart floating in physical space
- Interactive selection with haptic feedback
- Floating Swift Charts panels on tap

### Analytics Dashboard
- Total portfolio value and performance metrics
- Best and worst performing stocks
- Portfolio diversification breakdown

## Usage

1. **Create Portfolio:** Launch app and create your first portfolio
2. **Add Stocks:** Search and add stocks with purchase date and quantity
3. **View Dashboard:** Access analytics via menu button
4. **Enter AR Mode:** Tap menu → "View in AR" → Point at flat surface
5. **Interact:** Tap 3D bars to view charts, switch timeframes
6. **Sell Stocks:** Open stock detail → Tap "Sell Shares"

## Testing

Run unit tests in Xcode:
```bash
# Press Cmd+U in Xcode
# Or via command line:
xcodebuild test -scheme StockPortfolioAR -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

**Test Coverage:** 90%+ across models and business logic

## Known Limitations

- Alpha Vantage free tier: 25 API calls per day, 5 per minute
- Charts fall back to simulated data when API limit reached
- AR features require iPhone 6S or newer with ARKit support
- App must run on physical device for AR functionality

## Future Enhancements

- CloudKit sync for multi-device support
- WidgetKit home screen widgets showing portfolio value
- Push notifications for price alerts
- Advanced AR gestures (pinch to zoom, rotate)
- Multiple portfolio management
- Export to CSV/PDF reports
- Moving average crossover detection

## License

MIT License

## Author

**Dylan Vo**  
Computer Science Student @ Northeastern University  
Concentration in Artificial Intelligence

[LinkedIn](https://linkedin.com/in/dylan-vo-20k) | [GitHub](https://github.com/dylanvo20k)

---

*Built to demonstrate iOS development skills, AR visualization techniques, and modern Swift patterns including SwiftUI, SwiftData, async/await concurrency, and RealityKit integration.*
