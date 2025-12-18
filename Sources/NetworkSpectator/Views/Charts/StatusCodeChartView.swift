import SwiftUI
import Charts

struct StatusCodeChartView: View {
    let data: [ChartParameter<String>]
    
    var body: some View {
        Chart(data) {
            BarMark(
                x: .value("Status Code", $0.stringValue == "0" ? "Unknown" : $0.stringValue),
                y: .value("Count", $0.count)
            )
            .foregroundStyle(by: .value("Status Code", $0.stringValue == "0" ? "Unknown" : $0.stringValue))
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 300)
        .padding()
    }
}
