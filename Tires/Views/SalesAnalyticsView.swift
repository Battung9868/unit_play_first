//
//  SalesAnalyticsView.swift
//  Tires
//
//  Created on 04.11.2025.
//

import SwiftUI
import Charts

struct SalesAnalyticsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedChannel: SalesChannel?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Period selector
                    Picker("Period", selection: $dataManager.selectedPeriod) {
                        ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Overall channel statistics
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sales by Channel")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        let channelData = dataManager.getSalesByChannel(period: dataManager.selectedPeriod)
                        
                        if channelData.isEmpty {
                            EmptyChartView(message: "No sales data")
                        } else {
                            // Bar chart
                            if #available(iOS 16.0, *) {
                                Chart {
                                    ForEach(Array(channelData.sorted(by: { $0.value > $1.value })), id: \.key) { item in
                                        BarMark(
                                            x: .value("Channel", item.key.rawValue),
                                            y: .value("Quantity", item.value)
                                        )
                                        .foregroundStyle(item.key.color.gradient)
                                        .annotation(position: .top) {
                                            Text("\(item.value)")
                                                .font(.caption)
                                                .bold()
                                        }
                                    }
                                }
                                .frame(height: 300)
                                .padding(.horizontal)
                            }
                            
                            // Detailed statistics
                            VStack(spacing: 12) {
                                ForEach(SalesChannel.allCases, id: \.self) { channel in
                                    if let count = channelData[channel], count > 0 {
                                        ChannelStatCard(
                                            channel: channel,
                                            quantity: count,
                                            isSelected: selectedChannel == channel
                                        )
                                        .onTapGesture {
                                            withAnimation {
                                                selectedChannel = selectedChannel == channel ? nil : channel
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Details for selected channel
                    if let channel = selectedChannel {
                        ChannelDetailView(channel: channel, period: dataManager.selectedPeriod)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Sales Analytics")
        }
    }
}

// Channel statistics card
struct ChannelStatCard: View {
    let channel: SalesChannel
    let quantity: Int
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Channel icon
            Image(systemName: channel.icon)
                .font(.title2)
                .foregroundColor(channel.color)
                .frame(width: 50, height: 50)
                .background(channel.color.opacity(0.2))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(channel.rawValue)
                    .font(.headline)
                
                Text("\(quantity) pcs. sold")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? channel.color : Color.clear, lineWidth: 2)
                )
        )
    }
}

// Detailed information by channel
struct ChannelDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    let channel: SalesChannel
    let period: AnalyticsPeriod
    
    var salesForChannel: [Sale] {
        let dateRange = getDateRange(for: period)
        return dataManager.sales.filter {
            $0.channel == channel &&
            $0.date >= dateRange.start &&
            $0.date <= dateRange.end
        }
    }
    
    var topTiresForChannel: [(tire: Tire, quantity: Int)] {
        var tireQuantities: [UUID: (tire: Tire, quantity: Int)] = [:]
        
        for sale in salesForChannel {
            if var existing = tireQuantities[sale.tire.id] {
                existing.quantity += sale.quantity
                tireQuantities[sale.tire.id] = existing
            } else {
                tireQuantities[sale.tire.id] = (tire: sale.tire, quantity: sale.quantity)
            }
        }
        
        return tireQuantities.values.sorted { $0.quantity > $1.quantity }
    }
    
    private func getDateRange(for period: AnalyticsPeriod) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let end = now
        
        let start: Date
        switch period {
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            start = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            start = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        return (start, end)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Sales via \(channel.rawValue)")
                .font(.title3)
                .bold()
                .padding(.horizontal)
            
            if topTiresForChannel.isEmpty {
                Text("No sales through this channel")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                // Bar chart of top positions
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(Array(topTiresForChannel.prefix(5)), id: \.tire.id) { item in
                            BarMark(
                                x: .value("Model", item.tire.model),
                                y: .value("Quantity", item.quantity)
                            )
                            .foregroundStyle(channel.color.gradient)
                            .annotation(position: .top) {
                                Text("\(item.quantity)")
                                    .font(.caption2)
                                    .bold()
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                }
                
                // List of all sales
                VStack(spacing: 8) {
                    ForEach(topTiresForChannel.prefix(10), id: \.tire.id) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.tire.displayName)
                                    .font(.subheadline)
                                Text(item.tire.parameters)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(item.quantity) pcs.")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(channel.color)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}

#Preview {
    SalesAnalyticsView()
        .environmentObject(DataManager())
}
