//
//  Extensions.swift
//  StockPortfolioAR
//
//  Created by Dylan Vo on 10/27/25.
//

import Foundation

// You can add helpful extensions here later
// For example:

extension Double {
    var asCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}

extension Date {
    var asShortDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }
}
