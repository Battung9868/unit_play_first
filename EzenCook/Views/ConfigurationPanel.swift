import SwiftUI

struct ConfigurationPanel: View {
    
    
    @AppStorage("colorScheme") private var selectedColorScheme: String = "light"
    @State private var refreshID = UUID() // Force refresh when color scheme changes
    
    
    private let availableColorSchemes = ["light", "dark"]
    private let colorSchemeDisplayNames = ["Light", "Dark"]
    
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Appearance").foregroundColor(Color("Button"))) {
                    Picker("Appearance", selection: $selectedColorScheme) {
                        ForEach(Array(zip(availableColorSchemes, colorSchemeDisplayNames)), id: \.0) { value, label in
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
            .onAppear {
                if #available(iOS 16.0, *) {
                }
            }
        }
        .preferredColorScheme(selectedColorScheme == "dark" ? .dark : .light)
        .id(refreshID) // Force view refresh when color scheme changes
        .onChange(of: selectedColorScheme) { newValue in
            refreshID = UUID() // Trigger refresh when color scheme changes
        }
    }
}

#Preview {
    ConfigurationPanel()
        .preferredColorScheme(.dark)
} 
