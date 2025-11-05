//
//  SellTireView.swift
//  Tires
//
//  Created on 05.11.2025.
//

import SwiftUI

struct SellTireView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    let tire: Tire
    
    @State private var quantity = 1
    @State private var selectedChannel: SalesChannel = .shop
    @State private var showingSuccessAlert = false
    
    var maxQuantity: Int {
        tire.quantity
    }
    
    var totalPrice: Double {
        Double(quantity) * tire.price
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Tire information
                Section("Product") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tire.displayName)
                                .font(.headline)
                            Text(tire.type)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(tire.parameters)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("$\(Int(tire.price))")
                                .font(.headline)
                                .foregroundColor(.green)
                            Text("per tire")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Available in stock")
                        Spacer()
                        Text("\(tire.quantity) pcs.")
                            .bold()
                            .foregroundColor(tire.quantity > 0 ? .green : .red)
                    }
                }
                
                // Quantity selection
                Section("Quantity to Sell") {
                    Stepper("\(quantity) pcs.", value: $quantity, in: 1...max(1, maxQuantity))
                    
                    if quantity > maxQuantity {
                        Text("Not enough stock! Available: \(maxQuantity)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Sales channel selection
                Section("Sales Channel") {
                    Picker("Channel", selection: $selectedChannel) {
                        ForEach(SalesChannel.allCases, id: \.self) { channel in
                            HStack {
                                Image(systemName: channel.icon)
                                    .foregroundColor(channel.color)
                                Text(channel.rawValue)
                            }
                            .tag(channel)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Selected channel preview
                    HStack(spacing: 12) {
                        Image(systemName: selectedChannel.icon)
                            .font(.title2)
                            .foregroundColor(selectedChannel.color)
                            .frame(width: 50, height: 50)
                            .background(selectedChannel.color.opacity(0.2))
                            .cornerRadius(10)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedChannel.rawValue)
                                .font(.headline)
                            Text("Sales channel")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Total
                Section("Total") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        Text("\(quantity) × $\(Int(tire.price))")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Price")
                            .bold()
                        Spacer()
                        Text("$\(Int(totalPrice))")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Sell Tire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sell") {
                        sellTire()
                    }
                    .disabled(quantity > maxQuantity || quantity < 1)
                    .bold()
                }
            }
            .alert("Sale Completed!", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Successfully sold \(quantity) \(tire.displayName) via \(selectedChannel.rawValue)")
            }
        }
    }
    
    private func sellTire() {
        let sale = Sale(
            tire: tire,
            quantity: quantity,
            channel: selectedChannel,
            date: Date(),
            totalPrice: totalPrice
        )
        
        dataManager.addSale(sale)
        showingSuccessAlert = true
    }
}

#Preview {
    SellTireView(tire: Tire(
        brand: "Michelin",
        model: "Pilot Sport 4",
        type: "Summer",
        width: 225,
        profile: 45,
        radius: 17,
        quantity: 24,
        price: 15000
    ))
    .environmentObject(DataManager())
}



