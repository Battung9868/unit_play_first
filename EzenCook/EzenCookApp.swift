//
//  SparTimeApp.swift
//  SparTime
//
//  Created by Mateusz Ryba on 03/08/2025.
//

import SwiftUI
import SwiftData
import StoreKit
import CloudKit

@main
struct SparTimeApp: App {
    @StateObject private var cloudKitSyncManager = CloudKitSyncManager.shared
    @AppStorage("colorScheme") private var colorScheme: String = "light"
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showMainApp: Bool
    
    let modelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            UserSettings.self,
            WorkoutHistory.self
        ])
        
        print("\n🚀 [CloudKit] Initializing SparTime with CloudKit...")
        print("📱 [CloudKit] Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        
        // First try with iCloud sync
        do {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .automatic
            )
            print("☁️ [CloudKit] Attempting to create CloudKit container...")
            print("☁️ [CloudKit] Configuration: \(config)")
            
            // Add retry mechanism for CloudKit initialization
            var retryCount = 0
            let maxRetries = 3
            
            while retryCount < maxRetries {
                do {
                    let container = try ModelContainer(for: schema, configurations: [config])
                    print("✅ [CloudKit] Successfully created CloudKit container")
                    print("📊 [CloudKit] Checking initial data state...")
                    
                    // Check for existing items
                    let descriptor = FetchDescriptor<Item>()
                    if let items = try? container.mainContext.fetch(descriptor) {
                        print("📊 [CloudKit] Found \(items.count) existing items in CloudKit")
                    } else {
                        print("📊 [CloudKit] No existing items found in CloudKit")
                    }
                    
                    return container
                } catch {
                    retryCount += 1
                    print("⚠️ [CloudKit] Attempt \(retryCount) failed: \(error)")
                    
                    if retryCount < maxRetries {
                        print("🔄 [CloudKit] Retrying in 2 seconds...")
                        // Use Thread.sleep instead of Task.sleep for synchronous context
                        Thread.sleep(forTimeInterval: 2)
                        continue
                    }
                    throw error
                }
            }
            
            // This should never be reached due to the throw in the loop
            fatalError("Failed to create CloudKit container after \(maxRetries) attempts")
        } catch {
            print("❌ [CloudKit] Error creating iCloud ModelContainer: \(error)")
            print("⚠️ [CloudKit] Falling back to local storage...")
            
            // If iCloud fails, try with local storage
            do {
                let localConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    allowsSave: true
                )
                print("📱 [Local] Creating local storage container...")
                let container = try ModelContainer(for: schema, configurations: [localConfig])
                print("✅ [Local] Successfully created local container")
                return container
            } catch {
                print("❌ [Local] Error creating local ModelContainer: \(error)")
                print("⚠️ [Local] Falling back to in-memory storage...")
                
                // Last resort: in-memory storage
                do {
                    let memoryConfig = ModelConfiguration(
                        schema: schema,
                        isStoredInMemoryOnly: true
                    )
                    print("💾 [Memory] Creating in-memory container...")
                    let container = try ModelContainer(for: schema, configurations: [memoryConfig])
                    print("✅ [Memory] Successfully created in-memory container")
                    return container
                } catch {
                    print("❌ [Memory] FATAL ERROR: Could not create any ModelContainer: \(error)")
                    fatalError("Could not create any ModelContainer: \(error)")
                }
            }
        }
    }()
    
    init() {
        // Initialize showMainApp as Bool
        _showMainApp = State(initialValue: false)
        
        // Initialize app without purchase model
        let context = modelContainer.mainContext
    }
    
    private func initializeApp(with context: ModelContext) {
        Task {
            do {
                // Start CloudKit sync only if not already syncing
                if !CloudKitSyncManager.shared.isSyncing {
                    CloudKitSyncManager.shared.startInitialSync()
                }
            } catch {
                print("❌ Error during initialization: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main App
                showMainView()
                    .opacity(showMainApp ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: showMainApp)
                    .allowsHitTesting(showMainApp)

                // Onboarding
                if !hasSeenOnboarding {
                    OnboardingView(
                        pages: [
                            OnboardingPageModel(
                                title: "Konnichiwa to EzenCook",
                                description: "Sushi — on a timer We'll tell you when to remove the rice, add the nori. Customize the steps and save your favorite presets.",
                                imageName: "purchaseview-hero"
                            ),
                            OnboardingPageModel(
                                title: "How to Use EzenCook",
                                description: "1. Set your rolling time, rest time, and number of rolls.\n2. Customize for your sushi style and preparation intensity.\n3. Tap start and begin your sushi session!\n4. After finishing, check your progress and stats in the History tab.",
                                imageName: nil,
                                showsContinue: true,
                                showsPrimaryAction: false
                            ),
                            OnboardingPageModel(
                                title: "EzenCook — let's roll",
                                description: """
Set the time for one wrap.
1. Pick how many you're making.
2. Tap Roll it! to start.
3. Check your best in Stats.
""",
                                imageName: nil,
                                showsContinue: true,
                                showsPrimaryAction: false,
                                showsSecondaryAction: false,
                                bottomImageName: "signing"
                            )
                        ],
                        onFinish: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showMainApp = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                hasSeenOnboarding = true
                            }
                        }
                    )
                    .opacity(showMainApp ? 0 : 1)
                    .animation(.easeInOut(duration: 0.5), value: showMainApp)
                    .allowsHitTesting(!showMainApp)
                }
            }
            .preferredColorScheme(colorScheme == "dark" ? .dark : .light)
            .modelContainer(modelContainer)
            .onAppear {
                // Set showMainApp based on hasSeenOnboarding
                showMainApp = hasSeenOnboarding
            }
        }
    }
    
    private func showMainView() -> some View {
        return ContentView()
            .environment(\.modelContext, modelContainer.mainContext)
            .environmentObject(CloudKitSyncManager.shared)
    }
}

// CloudKit Sync Manager class to handle sync state
class CloudKitSyncManager: ObservableObject {
    static let shared = CloudKitSyncManager()
    
    @Published var isSyncing = false
    @Published var lastSyncError: String?
    @Published var syncStatus: String = "Ready"
    private var exportQueue: [() -> Void] = []
    private var isProcessingExport = false
    private var retryCount = 0
    private let maxRetries = 3
    
    private init() {}
    
    func startInitialSync() {
        if isSyncing {
            print("⚠️ [CloudKit] Sync already in progress, skipping...")
            return
        }
        
        DispatchQueue.main.async {
            print("🚀 [CloudKit] Starting initial sync...")
            self.isSyncing = true
            self.syncStatus = "Starting initial sync..."
            self.lastSyncError = nil
        }
    }
    
    func startSync() {
        guard !isSyncing else {
            print("⚠️ [CloudKit] Sync already in progress, skipping...")
            return
        }
        
        DispatchQueue.main.async {
            print("🔄 [CloudKit] Starting sync...")
            self.isSyncing = true
            self.syncStatus = "Syncing..."
            self.lastSyncError = nil
        }
    }
    
    func completeSync() {
        DispatchQueue.main.async {
            print("✅ [CloudKit] Sync completed")
            self.isSyncing = false
            self.syncStatus = "Sync completed"
        }
    }
    
    func queueExportRequest(_ request: @escaping () -> Void) {
        exportQueue.append(request)
        processNextExportRequest()
    }
    
    private func processNextExportRequest() {
        guard !isProcessingExport, !exportQueue.isEmpty else { return }
        
        isProcessingExport = true
        let request = exportQueue.removeFirst()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            do {
                request()
                self.syncStatus = "Export completed"
                self.lastSyncError = nil
                self.retryCount = 0
            } catch {
                print("❌ [CloudKit] Export failed: \(error)")
                self.lastSyncError = error.localizedDescription
                self.syncStatus = "Export failed"
                
                // Retry logic
                if self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    print("🔄 [CloudKit] Retrying export (attempt \(self.retryCount))...")
                    self.syncStatus = "Retrying export (attempt \(self.retryCount))..."
                    self.exportQueue.insert(request, at: 0)
                } else {
                    print("⚠️ [CloudKit] Max retries reached, giving up")
                    self.syncStatus = "Export failed after \(self.maxRetries) attempts"
                }
            }
            
            self.isProcessingExport = false
            self.processNextExportRequest()
        }
    }
}
