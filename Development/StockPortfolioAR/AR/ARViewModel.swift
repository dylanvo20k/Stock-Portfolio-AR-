import SwiftUI
import RealityKit
import ARKit

class ARViewModel: ObservableObject {
    @Published var isPlacementReady = false
    @Published var selectedStock: Stock?
    @Published var showingChart = false
    var arView: ARView?
    
    func setupAR(with stocks: [Stock]) {
        // Initial setup if needed
    }
    
    func selectStock(_ stock: Stock) {
        selectedStock = stock
        showingChart = true
        
        // Auto-dismiss after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.selectedStock?.id == stock.id {
                self.dismissStock()
            }
        }
    }
    
    func dismissStock() {
        withAnimation {
            showingChart = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.selectedStock = nil
        }
    }
    
    func resetView() {
        selectedStock = nil
        showingChart = false
        
        // Reset AR session
        if let arView = arView {
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal]
            arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        }
        
        isPlacementReady = false
    }
}
