//
//  WarehouseView.swift
//  Tires
//
//  Created on 04.11.2025.
//

import SwiftUI

struct WarehouseView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddTire = false
    @State private var searchText = ""
    @State private var sortOption: SortOption = .quantity
    
    enum SortOption: String, CaseIterable {
        case quantity = "By Quantity"
        case brand = "By Brand"
        case price = "By Price"
    }
    
    var filteredTires: [Tire] {
        var tires = dataManager.tires
        
        // Filter by search
        if !searchText.isEmpty {
            tires = tires.filter { tire in
                tire.brand.lowercased().contains(searchText.lowercased()) ||
                tire.model.lowercased().contains(searchText.lowercased()) ||
                tire.parameters.contains(searchText)
            }
        }
        
        // Sort
        switch sortOption {
        case .quantity:
            tires.sort { $0.quantity < $1.quantity }
        case .brand:
            tires.sort { $0.brand < $1.brand }
        case .price:
            tires.sort { $0.price < $1.price }
        }
        
        return tires
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and sort
                VStack(spacing: 12) {
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search by brand, model...", text: $searchText)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // Sort
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                
                // Statistics
                HStack(spacing: 20) {
                    StatBox(
                        title: "Total Items",
                        value: "\(dataManager.tires.count)",
                        icon: "shippingbox.fill",
                        color: .blue
                    )
                    
                    StatBox(
                        title: "Total Tires",
                        value: "\(dataManager.tires.reduce(0) { $0 + $1.quantity })",
                        icon: "rectangle.stack.fill",
                        color: .green
                    )
                    
                    let lowStock = dataManager.tires.filter { $0.quantity < 5 }.count
                    StatBox(
                        title: "Low Stock",
                        value: "\(lowStock)",
                        icon: "exclamationmark.triangle.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Tire list
                if filteredTires.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text(searchText.isEmpty ? "Warehouse is empty" : "Nothing found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        if searchText.isEmpty {
                            Button("Add Tires") {
                                showingAddTire = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredTires) { tire in
                                WarehouseTireCard(tire: tire)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Warehouse")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTire = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddTire) {
                AddEditTireView(tire: nil)
            }
        }
    }
}

// Warehouse tire card
struct WarehouseTireCard: View {
    @EnvironmentObject var dataManager: DataManager
    let tire: Tire
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingSellSheet = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Tire information
                VStack(alignment: .leading, spacing: 6) {
                    Text(tire.displayName)
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Label(tire.type, systemImage: "thermometer.sun.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(tire.parameters)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("$\(Int(tire.price))")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                // Quantity management
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Button(action: {
                            dataManager.updateTireQuantity(tire, newQuantity: tire.quantity - 1)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                        .disabled(tire.quantity == 0)
                        
                        Text("\(tire.quantity)")
                            .font(.title2)
                            .bold()
                            .frame(minWidth: 40)
                        
                        Button(action: {
                            dataManager.updateTireQuantity(tire, newQuantity: tire.quantity + 1)
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text("pcs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Action buttons
            HStack(spacing: 8) {
                // Sell button (prominent)
                Button(action: { showingSellSheet = true }) {
                    Label("Sell", systemImage: "cart.fill")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(tire.quantity == 0)
                
                // Edit button
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                
                // Delete button
                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingEditSheet) {
            AddEditTireView(tire: tire)
        }
        .sheet(isPresented: $showingSellSheet) {
            SellTireView(tire: tire)
        }
        .alert("Delete tire?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                dataManager.deleteTire(tire)
            }
        } message: {
            Text("Are you sure you want to delete \(tire.displayName)?")
        }
    }
}

// Add/Edit tire
struct AddEditTireView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    let tire: Tire?
    
    @State private var brand = ""
    @State private var model = ""
    @State private var type = "Summer"
    @State private var width = 205
    @State private var profile = 55
    @State private var radius = 16
    @State private var quantity = 0
    @State private var price = 10000.0
    
    let tireTypes = ["Summer", "Winter", "All-Season"]
    let widths = Array(stride(from: 145, through: 335, by: 10))
    let profiles = Array(stride(from: 30, through: 80, by: 5))
    let radiuses = Array(13...22)
    
    var isEditing: Bool {
        tire != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $model)
                    
                    Picker("Type", selection: $type) {
                        ForEach(tireTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }
                
                Section("Parameters") {
                    Picker("Width (mm)", selection: $width) {
                        ForEach(widths, id: \.self) { w in
                            Text("\(w)").tag(w)
                        }
                    }
                    
                    Picker("Profile (%)", selection: $profile) {
                        ForEach(profiles, id: \.self) { p in
                            Text("\(p)").tag(p)
                        }
                    }
                    
                    Picker("Radius (inches)", selection: $radius) {
                        ForEach(radiuses, id: \.self) { r in
                            Text("R\(r)").tag(r)
                        }
                    }
                }
                
                Section("Stock and Price") {
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 0...1000)
                    
                    HStack {
                        Text("Price")
                        TextField("Price", value: $price, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("$")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Tire" : "Add Tire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTire()
                    }
                    .disabled(brand.isEmpty || model.isEmpty)
                }
            }
            .onAppear {
                if let tire = tire {
                    brand = tire.brand
                    model = tire.model
                    type = tire.type
                    width = tire.width
                    profile = tire.profile
                    radius = tire.radius
                    quantity = tire.quantity
                    price = tire.price
                }
            }
        }
    }
    
    private func saveTire() {
        let newTire = Tire(
            id: tire?.id ?? UUID(),
            brand: brand,
            model: model,
            type: type,
            width: width,
            profile: profile,
            radius: radius,
            quantity: quantity,
            price: price
        )
        
        if isEditing {
            dataManager.updateTire(newTire)
        } else {
            dataManager.addTire(newTire)
        }
        
        dismiss()
    }
}

// Statistics widget
struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    WarehouseView()
        .environmentObject(DataManager())
}
