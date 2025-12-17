import SwiftUI
import Charts

struct HostsChartView: View {
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
