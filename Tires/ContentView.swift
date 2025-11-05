//
//  ContentView.swift
//  Tires
//
//  Created by Садыг Садыгов on 05.11.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager()
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            TireAnalyticsView()
                .tabItem {
                    Label("Tires", systemImage: "chart.pie.fill")
                }
            
            SalesAnalyticsView()
                .tabItem {
                    Label("Sales", systemImage: "chart.bar.fill")
                }
            
            WarehouseView()
                .tabItem {
                    Label("Warehouse", systemImage: "shippingbox.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .environmentObject(dataManager)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    ContentView()
}
