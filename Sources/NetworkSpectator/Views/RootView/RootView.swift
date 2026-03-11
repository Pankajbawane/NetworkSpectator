//
//  RootView.swift
//  NetworkSpectator
//
//  Created by Pankaj Bawane on 19/07/25.
//

import SwiftUI

struct RootView: View {
    @ObservedObject private var store = NetworkLogContainer.shared
    
    var body: some View {
        NavigationStack {
            RootContentView(logItems: store.items)
        }
    }
}

#Preview {
    RootView()
}
