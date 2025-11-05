//
//  HomeView.swift
//  Tires
//
//  Created on 04.11.2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Top 3 Sales
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🏆 Top Sales This Month")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        let topSales = dataManager.getTop3Sales()
                        
                        if topSales.isEmpty {
                            Text("No sales data")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(Array(topSales.enumerated()), id: \.element.tire.id) { index, item in
                                TopSaleCard(
                                    rank: index + 1,
                                    tire: item.tire,
                                    quantity: item.totalQuantity,
                                    channels: item.channels
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    // Warehouse Inventory
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📦 Warehouse Inventory")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        Text("From lowest to highest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        let sortedTires = dataManager.getTiresSortedByQuantity()
                        
                        ForEach(sortedTires) { tire in
                            InventoryCard(tire: tire)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isDarkMode.toggle()
                    }) {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

// Top Sale Card
struct TopSaleCard: View {
    let rank: Int
    let tire: Tire
    let quantity: Int
    let channels: [SalesChannel]
    
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rankEmoji)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tire.displayName)
                        .font(.headline)
                    Text(tire.type)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(quantity) pcs.")
                        .font(.headline)
                        .foregroundColor(.green)
                    Text(tire.parameters)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Sales Channels
            HStack(spacing: 8) {
                Text("Sold via:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(channels, id: \.self) { channel in
                    HStack(spacing: 4) {
                        Image(systemName: channel.icon)
                            .font(.caption)
                        Text(channel.rawValue)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(channel.color.opacity(0.2))
                    .foregroundColor(channel.color)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(rankColor.opacity(0.5), lineWidth: 2)
        )
    }
}

// Inventory Card
struct InventoryCard: View {
    @EnvironmentObject var dataManager: DataManager
    let tire: Tire
    @State private var showingSellSheet = false
    
    var quantityColor: Color {
        if tire.quantity == 0 {
            return .red
        } else if tire.quantity < 5 {
            return .orange
        } else if tire.quantity < 10 {
            return .yellow
        } else {
            return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Quantity indicator
                Circle()
                    .fill(quantityColor)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tire.displayName)
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Text(tire.type)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(tire.parameters)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(tire.quantity)")
                        .font(.title3)
                        .bold()
                        .foregroundColor(quantityColor)
                    
                    Text("pcs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            // Quick sell button
            if tire.quantity > 0 {
                Divider()
                
                Button(action: { showingSellSheet = true }) {
                    HStack {
                        Image(systemName: "cart.fill")
                        Text("Quick Sell")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderless)
                .tint(.blue)
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .sheet(isPresented: $showingSellSheet) {
            SellTireView(tire: tire)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(DataManager())
}
