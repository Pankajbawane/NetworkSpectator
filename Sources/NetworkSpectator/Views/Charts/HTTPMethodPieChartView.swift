import SwiftUI
import Charts

struct PieChartView: View {
    let data: [ChartParameter<String>]
    let title: String

    var body: some View {
        if #available(iOS 17, macOS 14, *) {
            Chart(data) {
                SectorMark(
                    angle: .value("Count", $0.count),
                    innerRadius: .ratio(0.4),
                    angularInset: 1
                )
                .foregroundStyle(by: .value(title, $0.value))
            }
            .frame(height: 300)
            .padding()
        } else {
            // Fallback for iOS/macOS versions earlier than 17/14
            Text("Chart requires iOS 17/macOS 14 or later.")
                .frame(height: 300)
                .padding()
        }
    }
}

struct HTTPMethodsChartView: View {
    let data: [ChartParameter<String>]

    var body: some View {
        Chart(data) {
            BarMark(
                x: .value("Hosts", $0.value),
                y: .value("Count", $0.count)
            )
            .foregroundStyle(by: .value("Hosts", $0.value))
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 300)
        .padding()
    }
}
