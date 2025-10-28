import Foundation
import SwiftData

@Model
class Transaction {
    var id: UUID
    var shares: Int
    var pricePerShare: Double
    var date: Date
    var type: TransactionType
    
    init(shares: Int, pricePerShare: Double, date: Date, type: TransactionType) {
        self.id = UUID()
        self.shares = shares
        self.pricePerShare = pricePerShare
        self.date = date
        self.type = type
    }
}

enum TransactionType: Codable {
    case buy
    case sell
}
