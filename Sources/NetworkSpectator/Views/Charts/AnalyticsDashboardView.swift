import SwiftUI

struct AnalyticsDashboardView: View {
    let data: [LogItem]
    
    var statusCode: [ChartParameter<String>] {
        ChartItemFactory.get(items: data, key: { "\($0.statusCode)" })
    }
    
    var httpMethod: [ChartParameter<String>] {
        ChartItemFactory.get(items: data, key: \.method)
    }
    
    var hosts: [ChartParameter<String>] {
        ChartItemFactory.get(items: data, key: \.host)
    }
    
    var body: some View {
        if data.isEmpty {
            Text("No data to display.")
        } else {
            ScrollView {
                VStack {
                    HStack {
                        VStack {
                            Text("Status Code")
                                .font(.caption)
                                .fontWeight(.bold)
                            StatusCodeChartView(data: statusCode)
                        }
                        
                        PieChartView(data: statusCode, title: "Status Code")
                    }
                    HStack {
                        VStack {
                            Text("HTTP Method")
                                .font(.caption)
                                .fontWeight(.bold)
                            HTTPMethodsChartView(data: httpMethod)
                        }
                        
                        PieChartView(data: httpMethod, title: "HTTP Methods")
                    }
                    HStack {
                        VStack {
                            Text("Host")
                                .font(.caption)
                                .fontWeight(.bold)
                            HostsChartView(data: hosts)
                        }
                        PieChartView(data: hosts, title: "Hosts")
                    }
                    Text("Requests")
                        .font(.caption)
                        .fontWeight(.bold)
                    RequestBarChartView(logs: data)
                }
            }
        }
    }
}
