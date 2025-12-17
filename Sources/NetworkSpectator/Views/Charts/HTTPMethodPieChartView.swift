import SwiftUI
import Charts

struct HTTPMethodPieChartView: View {
    let data: [ChartParameter<String>]

    var body: some View {
        #if targetEnvironment(iOS)
        Chart(data) {
            SectorMark(
                angle: .value("Count", $0.count),
                innerRadius: .ratio(0.4),
                angularInset: 1
            )
            .foregroundStyle(by: .value("HTTP Method", $0.value))
        }
        .frame(height: 300)
        .padding()
        #endif
    }
}
