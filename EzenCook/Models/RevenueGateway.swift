


import Foundation
import StoreKit
import Combine

@MainActor
class RevenueGateway: ObservableObject {
    
    
    static let shared = RevenueGateway()
    
    
    @Published var catalogIdentifiers: [String]
    @Published var inventoryMetadata: [ProductMetadata] = []
    @Published var products: [Product] = []
    
    @Published var hasActiveEntitlement: Bool = false
    @Published var isProcessingAcquisition: Bool = false
    @Published var isFetchingProducts: Bool = false
    @Published var isCheckingTransactions: Bool = true
    
    
    private var updateListenerTask: Task<Void, Error>?
    private var hasLoadedProducts = false
    private var isInitialized = false
    
    
    var isUserSubscribedSync: Bool {
        hasActiveEntitlement
    }
    
    
    func isUserSubscribed() async -> Bool {
        hasActiveEntitlement
    }
    
    func canAddNewSpar(currentCount: Int, maxFreeSpars: Int) -> Bool {
        print("\n🔒 [RevenueGateway] Checking if can add new spar:")
        print("   - Current count: \(currentCount)")
        print("   - Max free spars: \(maxFreeSpars)")
        print("   - Is subscribed: \(hasActiveEntitlement)")
        
        if hasActiveEntitlement {
            print("   ✅ User is subscribed, can add spar")
            return true
        }
        let canAdd = currentCount < maxFreeSpars
        print("   \(canAdd ? "✅" : "❌") User can add spar: \(canAdd) (\(currentCount)/\(maxFreeSpars) used)")
        return canAdd
    }
    
    func canAddNewSpar(currentCount: Int, maxFreeSpars: Int) async -> Bool {
        if hasActiveEntitlement { return true }
        return currentCount < maxFreeSpars
    }
    
    private init() {
        self.catalogIdentifiers = ["spartime_pro"] // Single one-time purchase product
        self.inventoryMetadata = [
            ProductMetadata(price: "$4.99", productId: "spartime_pro", duration: "lifetime", durationPlanName: "Unlock All Features", hasTrial: false)
        ]
    }
    
    func quickSubscriptionCheck() async -> Bool {
        print("\n💎 [RevenueGateway] Performing quick subscription check...")
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                print("Found verified transaction: \(transaction.id)")
                let isPurchased = transaction.productType == .nonConsumable || transaction.productType == .nonRenewable
                print("Is One-Time Purchase: \(isPurchased)")
                
                await MainActor.run {
                    hasActiveEntitlement = isPurchased
                }
                return isPurchased
            }
        }
        
        return false
    }
    
    func initialize() async {
        guard !isInitialized else { return }
        
        _ = await quickSubscriptionCheck()
        
        isInitialized = true
        print("\n=== Initial Setup ===")
        
        updateListenerTask = listenForTransactions()
        
        await fetchCatalogInventory()
        
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
        
        let isPurchased = transaction.productType == .nonConsumable || transaction.productType == .nonRenewable
        print("Is One-Time Purchase: \(isPurchased)")
        
        await MainActor.run {
            hasActiveEntitlement = isPurchased
        }
        print("Updated hasActiveEntitlement to: \(isPurchased)")
        
        await transaction.finish()
        print("Transaction finished")
        print("=== End Transaction Handling ===\n")
    }
    
    private func fetchCatalogInventory() async {
        guard !hasLoadedProducts else { return }
        
        isFetchingProducts = true
        defer { 
            isFetchingProducts = false
            hasLoadedProducts = true
        }
        
        do {
            products = try await Product.products(for: catalogIdentifiers)
            print("\n=== Product Loading Results ===")
            print("Total products loaded: \(products.count)")
            
            for product in products {
                print("\nProduct: \(product.id)")
                print("Display Name: \(product.displayName)")
                print("Description: \(product.description)")
                print("Price: \(product.displayPrice)")
                print("Subscription Period: \(product.subscription?.subscriptionPeriod.unit ?? .month)")
                
                if let introOffer = product.subscription?.introductoryOffer {
                    print("Intro Offer Available:")
                    print("- Type: \(introOffer.period)")
                    print("- Price: \(introOffer.price)")
                    print("- Period: \(introOffer.period)")
                } else {
                    print("No intro offer available")
                }
                
                if let index = inventoryMetadata.firstIndex(where: { $0.productId == product.id }) {
                    inventoryMetadata[index].price = product.displayPrice
                    print("Updated local price to: \(product.displayPrice)")
                }
            }
            print("\n=== End Product Loading Results ===\n")
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func initiateAcquisition(productId: String) {
        guard let product = products.first(where: { $0.id == productId }) else {
            print("Product not found: \(productId)")
            return
        }
        
        print("\n=== Starting Purchase ===")
        print("Product ID: \(productId)")
        print("Product Type: \(product.type)")
        
        Task {
            isProcessingAcquisition = true
            defer { isProcessingAcquisition = false }
            
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
    
    func reconcileEntitlements() {
        Task {
            isProcessingAcquisition = true
            defer { isProcessingAcquisition = false }
            
            do {
                try await AppStore.sync()
                print("Purchases restored successfully")
            } catch {
                print("Failed to restore purchases: \(error)")
            }
        }
    }
    
    private func updateProductDetails() async {
    }
}

class ProductMetadata: ObservableObject, Identifiable {
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

