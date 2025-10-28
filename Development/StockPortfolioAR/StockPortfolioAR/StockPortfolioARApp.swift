import SwiftUI
import SwiftData

@main
struct StockPortfolioARApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Portfolio.self, Stock.self, Transaction.self])
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var portfolios: [Portfolio]
    @State private var showingCreatePortfolio = false
    @State private var portfolioName = ""
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                // Show loading briefly then show UI
                ProgressView("Loading...")
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isLoading = false
                        }
                    }
            } else if let portfolio = portfolios.first {
                // Portfolio exists - show main view
                PortfolioListView()
            } else {
                // No portfolio - show creation screen
                VStack(spacing: 24) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                    
                    Text("Welcome to Stock Portfolio AR")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Create your first portfolio to get started")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                        .frame(height: 40)
                    
                    Button {
                        showingCreatePortfolio = true
                    } label: {
                        Text("Create Portfolio")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 40)
                }
                .padding()
                .sheet(isPresented: $showingCreatePortfolio) {
                    NavigationStack {
                        Form {
                            Section("Portfolio Details") {
                                TextField("Portfolio Name", text: $portfolioName)
                                    .textInputAutocapitalization(.words)
                            }
                            
                            Section {
                                Button("Create") {
                                    createPortfolio()
                                }
                                .frame(maxWidth: .infinity)
                                .disabled(portfolioName.isEmpty)
                            }
                        }
                        .navigationTitle("New Portfolio")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    showingCreatePortfolio = false
                                    portfolioName = ""
                                }
                            }
                        }
                    }
                    .presentationDetents([.medium])
                }
            }
        }
    }
    
    private func createPortfolio() {
        let portfolio = Portfolio(clientName: portfolioName)
        modelContext.insert(portfolio)
        try? modelContext.save()
        showingCreatePortfolio = false
        portfolioName = ""
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Portfolio.self, Stock.self, Transaction.self])
}
