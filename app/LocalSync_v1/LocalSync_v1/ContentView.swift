//
//  ContentView.swift
//  LocalSync_v1
//
//  Created by Sascha Molina on 19.07.26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        SyncDashboardView(viewModel: AppContainer.makeSyncViewModel())
    }
}

#Preview {
    ContentView()
}
