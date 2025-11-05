//
//  SettingsView.swift
//  Tires
//
//  Created on 04.11.2025.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingDeleteTopAlert = false
    @State private var showingDeleteAllAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Appearance section
                Section("Appearance") {
                    Toggle(isOn: $isDarkMode) {
                        Label("Dark Theme", systemImage: isDarkMode ? "moon.fill" : "sun.max.fill")
                    }
                }
                
                // Data management section
                Section("Data Management") {
                    Button(role: .destructive, action: { showingDeleteTopAlert = true }) {
                        Label("Delete Top Data", systemImage: "chart.bar.xaxis")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteAllAlert = true }) {
                        Label("Delete All Data", systemImage: "trash.fill")
                    }
                }
                
                // About section
                Section("About") {
                    Button(action: requestReview) {
                        Label("Rate App", systemImage: "star.fill")
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Statistics section
                Section("Statistics") {
                    HStack {
                        Text("Warehouse Items")
                        Spacer()
                        Text("\(dataManager.tires.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Tires")
                        Spacer()
                        Text("\(dataManager.tires.reduce(0) { $0 + $1.quantity })")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Sales")
                        Spacer()
                        Text("\(dataManager.sales.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Tires Sold")
                        Spacer()
                        Text("\(dataManager.sales.reduce(0) { $0 + $1.quantity })")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Delete Top Data?", isPresented: $showingDeleteTopAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    dataManager.deleteTopData()
                }
            } message: {
                Text("All sales from the last month will be deleted. This action cannot be undone.")
            }
            .alert("Delete All Data?", isPresented: $showingDeleteAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    dataManager.deleteAllData()
                }
            } message: {
                Text("ALL data about tires and sales will be deleted. This action cannot be undone!")
            }
        }
    }
    
    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager())
}
