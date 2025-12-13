import SwiftUI

struct AnalyticsDashboardView: View {
    let data: [LogItem]
    
    var statusCode: [ChartParameter<Int>] {
        ChartItemFactory.get(items: data, key: \.statusCode)
    }
    
    var httpMethod: [ChartParameter<String>] {
        ChartItemFactory.get(items: data, key: \.method)
    }
    
    var hosts: [ChartParameter<String>] {
        ChartItemFactory.get(items: data, key: \.host)
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Status Code")
                    .font(.caption)
                    .fontWeight(.bold)
                StatusCodeChartView(data: statusCode)
                Text("HTTP Method")
                    .font(.caption)
                    .fontWeight(.bold)
                HTTPMethodPieChartView(data: httpMethod)
                Text("Host")
                    .font(.caption)
                    .fontWeight(.bold)
                HostsChartView(data: hosts)
            }
        }
    }
}
