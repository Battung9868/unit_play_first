// PurchaseModel SwiftUI
// Created by Adam Lyttle on 7/18/2024

// Make cool stuff and share your build with me:

//  --> x.com/adamlyttleapps
//  --> github.com/adamlyttleapps

import Foundation
import StoreKit
import SwiftData

@MainActor
class PurchaseModel: ObservableObject {
    
    static let shared = PurchaseModel()
    
    @Published var productIds: [String]
    @Published var productDetails: [PurchaseProductDetails] = []
    @Published var products: [Product] = []
    
    @Published var isSubscribed: Bool = false
    @Published var isPurchasing: Bool = false
    @Published var isFetchingProducts: Bool = false
    @Published var isCheckingTransactions: Bool = true  // New state for transaction check
    
    private var updateListenerTask: Task<Void, Error>?
    private var modelContext: ModelContext?
    private var subscriptionStatus: SubscriptionStatus?
    private var hasLoadedProducts = false
    private var isInitialized = false
    
    // Synchronous method to check subscription status
    var isUserSubscribedSync: Bool {
        isSubscribed
    }
    
    // Non-isolated method to check subscription status
    func isUserSubscribed() async -> Bool {
        await isSubscribed
    }
    
    // Synchronous method to check if user can add more spars
    func canAddNewSpar(currentCount: Int, maxFreeSpars: Int) -> Bool {
        print("\n🔒 [PurchaseModel] Checking if can add new spar:")
        print("   - Current count: \(currentCount)")
        print("   - Max free spars: \(maxFreeSpars)")
        print("   - Is subscribed: \(isSubscribed)")
        
        if isSubscribed {
            print("   ✅ User is subscribed, can add spar")
            return true
        }
        let canAdd = currentCount < maxFreeSpars
        print("   \(canAdd ? "✅" : "❌") User can add spar: \(canAdd) (\(currentCount)/\(maxFreeSpars) used)")
        return canAdd
    }
    
    // Non-isolated method to check if user can add more spars
    func canAddNewSpar(currentCount: Int, maxFreeSpars: Int) async -> Bool {
        if await isSubscribed { return true }
        return currentCount < maxFreeSpars
    }
    
    private init() {
        //initialise your productids and product details
        self.productIds = ["spartime_pro"] // Single one-time purchase product
        self.productDetails = [
            PurchaseProductDetails(price: "$4.99", productId: "spartime_pro", duration: "lifetime", durationPlanName: "Unlock All Features", hasTrial: false)
        ]
    }
    
    // Quick subscription check that runs before full initialization
    func quickSubscriptionCheck() async -> Bool {
        print("\n💎 [PurchaseModel] Performing quick subscription check...")
        
        // Check for existing transactions first
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                print("Found verified transaction: \(transaction.id)")
                let isPurchased = transaction.productType == .nonConsumable || transaction.productType == .nonRenewable
                print("Is One-Time Purchase: \(isPurchased)")
                
                // Update subscription status immediately
                await MainActor.run {
                    updateSubscriptionStatus(isPurchased)
                }
                return isPurchased
            }
        }
        
        // If no transactions found, check CloudKit status
        if let context = modelContext {
            let descriptor = FetchDescriptor<SubscriptionStatus>()
            if let status = try? context.fetch(descriptor).first {
                print("Found existing subscription status in CloudKit")
                return status.isSubscribed ?? false
            }
        }
        
        return false
    }
    
    func initialize() async {
        guard !isInitialized else { return }
        
        // Do quick subscription check first
        _ = await quickSubscriptionCheck()
        
        isInitialized = true
        print("\n=== Initial Setup ===")
        
        // Start listening for transactions
        updateListenerTask = listenForTransactions()
        
        // Load products and check transactions
        await loadProducts()
        
        // Check for existing transactions
        print("\n=== Checking Existing Transactions ===")
        isCheckingTransactions = true
        defer { isCheckingTransactions = false }
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                print("Found verified transaction: \(transaction.id)")
                await handle(transactionResult: result)
            }
        }
        print("=== End Transaction Check ===\n")
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadSubscriptionStatus()
    }
    
    private func loadSubscriptionStatus() {
        guard let context = modelContext else { return }
        
        print("\n💎 [PurchaseModel] Loading subscription status...")
        let descriptor = FetchDescriptor<SubscriptionStatus>()
        if let status = try? context.fetch(descriptor).first {
            subscriptionStatus = status
            isSubscribed = status.isSubscribed ?? false
            print("💎 [PurchaseModel] Found existing subscription status:")
            print("   - Is Subscribed: \(status.isSubscribed ?? false)")
            print("   - Last Updated: \(status.lastUpdated?.description ?? "never")")
        } else {
            print("💎 [PurchaseModel] No existing subscription status found, creating new...")
            // Create new subscription status if none exists
            subscriptionStatus = SubscriptionStatus()
            context.insert(subscriptionStatus!)
            try? context.save()
            print("💎 [PurchaseModel] Created new subscription status")
        }
    }
    
    private func updateSubscriptionStatus(_ newStatus: Bool) {
        guard let context = modelContext else { return }
        
        print("\n💎 [PurchaseModel] Updating subscription status...")
        print("   - New Status: \(newStatus)")
        
        if subscriptionStatus == nil {
            subscriptionStatus = SubscriptionStatus()
            context.insert(subscriptionStatus!)
            print("💎 [PurchaseModel] Created new subscription status object")
        }
        
        subscriptionStatus?.isSubscribed = newStatus
        subscriptionStatus?.lastUpdated = Date()
        isSubscribed = newStatus
        
        try? context.save()
        print("💎 [PurchaseModel] Subscription status updated and saved")
        print("   - Is Subscribed: \(newStatus)")
        print("   - Last Updated: \(Date().description)")
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                await self.handle(transactionResult: result)
            }
        }
    }
    
    private func handle(transactionResult: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = transactionResult else {
            print("Transaction verification failed")
            return
        }
        
        print("\n=== Transaction Handling ===")
        print("Transaction ID: \(transaction.id)")
        print("Product ID: \(transaction.productID)")
        print("Product Type: \(transaction.productType)")
        print("Original Transaction ID: \(transaction.originalID)")
        
        // For one-time purchases, we consider any verified transaction as a successful purchase
        let isPurchased = transaction.productType == .nonConsumable || transaction.productType == .nonRenewable
        print("Is One-Time Purchase: \(isPurchased)")
        
        // Update subscription status in SwiftData (we'll use the same field for one-time purchases)
        await MainActor.run {
            updateSubscriptionStatus(isPurchased)
        }
        print("Updated isSubscribed to: \(isPurchased)")
        
        // Always finish a transaction
        await transaction.finish()
        print("Transaction finished")
        print("=== End Transaction Handling ===\n")
    }
    
    private func loadProducts() async {
        // Skip if products are already loaded
        guard !hasLoadedProducts else { return }
        
        isFetchingProducts = true
        defer { 
            isFetchingProducts = false
            hasLoadedProducts = true
        }
        
        do {
            products = try await Product.products(for: productIds)
            print("\n=== Product Loading Results ===")
            print("Total products loaded: \(products.count)")
            
            // Update product details with actual prices
            for product in products {
                print("\nProduct: \(product.id)")
                print("Display Name: \(product.displayName)")
                print("Description: \(product.description)")
                print("Price: \(product.displayPrice)")
                print("Subscription Period: \(product.subscription?.subscriptionPeriod.unit ?? .month)")
                
                // Check for intro offers
                if let introOffer = product.subscription?.introductoryOffer {
                    print("Intro Offer Available:")
                    print("- Type: \(introOffer.period)")
                    print("- Price: \(introOffer.price)")
                    print("- Period: \(introOffer.period)")
                } else {
                    print("No intro offer available")
                }
                
                if let index = productDetails.firstIndex(where: { $0.productId == product.id }) {
                    productDetails[index].price = product.displayPrice
                    print("Updated local price to: \(product.displayPrice)")
                }
            }
            print("\n=== End Product Loading Results ===\n")
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchaseProduct(productId: String) {
        guard let product = products.first(where: { $0.id == productId }) else {
            print("Product not found: \(productId)")
            return
        }
        
        print("\n=== Starting Purchase ===")
        print("Product ID: \(productId)")
        print("Product Type: \(product.type)")
        
        Task {
            isPurchasing = true
            defer { isPurchasing = false }
            
            do {
                let result = try await product.purchase()
                print("Purchase result received")
                
                switch result {
                case .success(let verification):
                    print("Purchase successful, handling transaction")
                    await handle(transactionResult: verification)
                case .userCancelled:
                    print("User cancelled the purchase")
                case .pending:
                    print("Purchase is pending")
                @unknown default:
                    print("Unknown purchase result")
                }
            } catch {
                print("Purchase failed: \(error)")
            }
            print("=== End Purchase ===\n")
        }
    }
    
    func restorePurchases() {
        Task {
            isPurchasing = true
            defer { isPurchasing = false }
            
            do {
                try await AppStore.sync()
                print("Purchases restored successfully")
            } catch {
                print("Failed to restore purchases: \(error)")
            }
        }
    }
    
    private func updateProductDetails() async {
        // This method can be used to update product details after a successful purchase
        // For example, updating prices or trial status
    }
}

class PurchaseProductDetails: ObservableObject, Identifiable {
    let id: UUID
    
    @Published var price: String = ""
    @Published var productId: String = ""
    @Published var duration: String = ""
    @Published var durationPlanName: String = ""
    @Published var hasTrial: Bool = false
    
    init(price: String = "", productId: String = "", duration: String = "", durationPlanName: String = "", hasTrial: Bool = false) {
        self.id = UUID()
        self.price = price
        self.productId = productId
        self.duration = duration
        self.durationPlanName = durationPlanName
        self.hasTrial = hasTrial
    }
}

