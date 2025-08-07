


https://github.com/user-attachments/assets/731bcee1-6ed4-4404-8dd0-60ebb0779a29



🔥 HeatMapView

HeatMapView is a lightweight and fully SwiftUI-based layout component that visualizes a collection of data items as a heatmap using a squarified treemap layout. It’s ideal for displaying weighted distributions such as market caps, user activity, or statistical heat values.

> 📝 **Note:**  
> The layout algorithm is based on Yahoo/YMTreeMap, originally implemented by Yahoo ([Yahoo/YMTreeMap](https://github.com/yahoo/YMTreeMap.git)).
All credits for the squarified treemap algorithm go to their excellent open-source work.

⸻

✨ Features

• 📐 Squarified TreeMap layout algorithm

• 🔥 Dynamically sizes rectangles based on a heat value

• 🧱 Accepts any Identifiable & Sendable model conforming to HeatMapValue

• 🎨 Customizable content for each heatmap cell

• 🧪 100% SwiftUI, no dependencies

🚀 Quick Start

1. Define your data model

```swift
struct Stock: HeatMapValue {
    let id: UUID
    let symbol: String
    let marketCap: Double

    var heat: Double { marketCap }
}
```

2. Create a custom view for each cell

```swift
struct StockItemView: View {
    let stock: Stock
    let normalizedHeat: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 1, green: 1 - normalizedHeat, blue: 0)) // heat → red-yellow
            VStack {
                Text(stock.symbol).bold()
                Text("\(Int(stock.marketCap))B")
                    .font(.caption)
            }
            .padding(4)
        }
    }
}
```

3. Use HeatMapView

```swift
HeatMapView(items: stocks) { stock, normalizedHeat in
    StockItemView(stock: stock, normalizedHeat: normalizedHeat)
}
```

📦 Installation

Swift Package Manager (Recommended)

1. Open your Xcode project

2. Go to File > Add Packages…

3. Enter the URL of this repository:

```bash
https://github.com/Anderson-Hyl/HeatMap.git
```

🪪 License

MIT © [Anderson-Hyl]
