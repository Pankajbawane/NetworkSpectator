//
//  HTTPMethodsChartView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 07/12/25.
//

import SwiftUI
import Charts

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
