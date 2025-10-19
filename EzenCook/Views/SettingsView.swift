import SwiftUI

struct SettingsView: View {
    @State private var refreshID = UUID() // Force refresh when color scheme changes
    @AppStorage("colorScheme") private var colorScheme: String = "light"
    let colorSchemes = ["light", "dark"]
    let colorSchemeLabels = ["Light", "Dark"]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Appearance").foregroundColor(Color("Button"))) {
                    Picker("Appearance", selection: $colorScheme) {
                        ForEach(Array(zip(colorSchemes, colorSchemeLabels)), id: \.0) { value, label in
                            Text(label).tag(value)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .listRowBackground(Color("Border"))
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color("Background"))
            .scrollContentBackground(.hidden)
        }
        .preferredColorScheme(colorScheme == "dark" ? .dark : .light)
        .id(refreshID) // Force view refresh when color scheme changes
        .onChange(of: colorScheme) { _, _ in
            refreshID = UUID() // Trigger refresh when color scheme changes
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
} 
