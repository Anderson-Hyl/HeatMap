import HeatMap
import SwiftUI

struct Stock: HeatMapValue {
    let id: UUID
    let symbol: String
    let name: String
    var marketCap: Double

    var heat: Double {
        marketCap
    }
}

struct StockItemView: View {
    let stock: Stock
    let normalizedHeat: Double
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.random)
            VStack {
                Text(stock.symbol)
                    .bold()
                    .foregroundColor(Color(.black))
                Text(String(format: "%.0fB", stock.marketCap))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(4)
        }
    }
}

struct ContentView: View {
    @State private var stocks: [Stock] = [
        .init(id: UUID(), symbol: "AAPL", name: "Apple", marketCap: 2500),
        .init(id: UUID(), symbol: "GOOG", name: "Google", marketCap: 1800),
        .init(id: UUID(), symbol: "AMZN", name: "Amazon", marketCap: 1600),
        .init(id: UUID(), symbol: "TSLA", name: "Tesla", marketCap: 900),
        .init(id: UUID(), symbol: "MSFT", name: "Microsoft", marketCap: 2700),
        .init(id: UUID(), symbol: "META", name: "Meta", marketCap: 800),
    ]
    var body: some View {
        VStack {
            HeatMapView(items: stocks) { stock, normalized in
                Button {
                    
                } label: {
                    StockItemView(stock: stock, normalizedHeat: normalized)
                }
                .buttonStyle(.plain)
            }
            Button("+") {
                withAnimation {
                    stocks[0].marketCap = 600
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
    }
}

extension Color {
    /// Generates a random color with a random opacity.
    ///
    /// - Returns: A new Color instance with random RGB and opacity values.
    static var random: Color {
        // Generate random values for red, green, and blue components.
        // The values are in the range of 0.0 to 1.0.
        let red = Double.random(in: 0...1)
        let green = Double.random(in: 0...1)
        let blue = Double.random(in: 0...1)
        
        // Generate a random value for opacity.
        let opacity = Double.random(in: 0.8...1) // Opacity is slightly higher to ensure visibility.
        
        return Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

#Preview {
    ContentView()
        .frame(height: 600)
}
