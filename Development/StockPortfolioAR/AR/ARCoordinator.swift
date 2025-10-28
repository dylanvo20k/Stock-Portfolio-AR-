import UIKit
import RealityKit
import ARKit

extension ARViewContainer {
    class Coordinator: NSObject, ARSessionDelegate {
        let stocks: [Stock]
        let viewModel: ARViewModel
        var arView: ARView?
        var portfolioAnchor: AnchorEntity?
        var stockEntities: [String: ModelEntity] = [:]
        
        init(stocks: [Stock], viewModel: ARViewModel) {
            self.stocks = stocks
            self.viewModel = viewModel
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard portfolioAnchor == nil else { return }
            
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor,
                   planeAnchor.alignment == .horizontal {
                    
                    DispatchQueue.main.async {
                        self.viewModel.isPlacementReady = true
                        self.placePortfolio(at: planeAnchor)
                    }
                    break
                }
            }
        }
        
        func placePortfolio(at anchor: ARPlaneAnchor) {
            guard let arView = arView, portfolioAnchor == nil else { return }
            
            // Create anchor at plane center
            let anchorEntity = AnchorEntity(world: anchor.transform)
            
            // Calculate total portfolio value for scaling
            let totalValue = stocks.reduce(0.0) { $0 + $1.currentValue }
            
            // Create 3D bars for each stock
            let stockCount = stocks.count
            let spacing: Float = 0.15
            let columns = min(stockCount, 4)
            
            for (index, stock) in stocks.enumerated() {
                let row = Float(index / columns)
                let col = Float(index % columns)
                
                // Position
                let x = (col - Float(columns) / 2.0) * spacing
                let z = row * spacing
                
                // Height based on portfolio percentage
                let percentage = stock.currentValue / totalValue
                let height = Float(percentage * 0.5) + 0.05 // Scale height
                
                // Create bar
                let barEntity = createStockBar(
                    stock: stock,
                    height: height,
                    position: SIMD3(x: x, y: height / 2, z: z)
                )
                
                anchorEntity.addChild(barEntity)
                stockEntities[stock.tickerSymbol] = barEntity
                
                // Add floating label
                let label = createLabel(text: stock.tickerSymbol, height: height)
                label.position = SIMD3(x: x, y: height + 0.05, z: z)
                anchorEntity.addChild(label)
            }
            
            arView.scene.addAnchor(anchorEntity)
            portfolioAnchor = anchorEntity
        }
        
        func createStockBar(stock: Stock, height: Float, position: SIMD3<Float>) -> ModelEntity {
            // Create box mesh
            let mesh = MeshResource.generateBox(width: 0.08, height: height, depth: 0.08)
            
            // Material with color based on performance
            var material = SimpleMaterial()
            
            if stock.gainLossPercent > 0 {
                material.color = .init(tint: .green.withAlphaComponent(0.8))
            } else if stock.gainLossPercent < 0 {
                material.color = .init(tint: .red.withAlphaComponent(0.8))
            } else {
                material.color = .init(tint: .gray.withAlphaComponent(0.8))
            }
            
            // Create entity
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.position = position
            entity.name = stock.tickerSymbol
            
            // Enable collision for tap detection
            entity.generateCollisionShapes(recursive: false)
            
            // Add gentle pulse animation
            let duration: TimeInterval = 2.0
            var transform = entity.transform
            transform.scale = SIMD3(1.05, 1.05, 1.05)
            
            entity.move(
                to: transform,
                relativeTo: entity.parent,
                duration: duration,
                timingFunction: .easeInOut
            )
            
            return entity
        }
        
        func createLabel(text: String, height: Float) -> ModelEntity {
            let mesh = MeshResource.generateText(
                text,
                extrusionDepth: 0.001,
                font: .systemFont(ofSize: 0.03),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byTruncatingTail
            )
            
            var material = SimpleMaterial()
            material.color = .init(tint: .white)
            
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.scale = SIMD3(0.5, 0.5, 0.5)
            
            return entity
        }
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            
            let location = recognizer.location(in: arView)
            
            print("👆 Tap detected at: \(location)")
            
            // Try entity-based hit test first
            let hitEntities = arView.entities(at: location)
            
            if let entity = hitEntities.first {
                print("✅ Hit entity: \(entity.name)")
                
                // Find the stock by entity name
                if let stock = stocks.first(where: { $0.tickerSymbol == entity.name }) {
                    print("🎯 Found stock: \(stock.tickerSymbol)")
                    viewModel.selectStock(stock)
                    
                    // Highlight animation
                    var transform = entity.transform
                    let originalScale = transform.scale
                    transform.scale = SIMD3(1.3, 1.3, 1.3)
                    entity.move(to: transform, relativeTo: entity.parent, duration: 0.2)
                    
                    // Return to normal
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        var resetTransform = entity.transform
                        resetTransform.scale = originalScale
                        entity.move(to: resetTransform, relativeTo: entity.parent, duration: 0.2)
                    }
                    
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    return
                }
            }
            
            print("❌ No entity hit at tap location")
            
            // Fallback: Check distance to all entities
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
            
            if let result = results.first {
                print("📍 Raycast hit at: \(result.worldTransform.translation)")
                
                // Find closest stock entity
                var closestStock: Stock?
                var closestDistance: Float = .infinity
                
                for (symbol, entity) in stockEntities {
                    let distance = entity.position.distance(to: result.worldTransform.translation)
                    print("  Distance to \(symbol): \(distance)")
                    
                    if distance < 0.15 && distance < closestDistance {
                        closestDistance = distance
                        closestStock = stocks.first(where: { $0.tickerSymbol == symbol })
                    }
                }
                
                if let stock = closestStock {
                    print("🎯 Found closest stock: \(stock.tickerSymbol)")
                    viewModel.selectStock(stock)
                    
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                } else {
                    print("❌ No stock within range")
                }
            } else {
                print("❌ Raycast missed")
            }
        }
    }
}
