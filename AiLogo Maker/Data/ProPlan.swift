//
//  ProPlan.swift
//  Ai Image Art
//
//  Created by Apple on 04/10/2025.
//


import Foundation
import StoreKit

// MARK: - Types

public enum ProPlan: Hashable {
    case yearly
    case weekly
    case weeklyTrial
}

struct Plan: Identifiable, Hashable {
    enum Kind: Hashable { case yearly, weekly, weeklyTrial }
    let id: Int
    let kind: Kind
    let title: String
    let subtitle: String
    let priceText: String
    let tagText: String?

    static func yearly(id: Int,priceText: String, subtitle: String, tag: String?) -> Plan {
        .init(id: id,kind: .yearly, title: "Yearly", subtitle: subtitle, priceText: priceText, tagText: tag)
    }
    static func weekly(id: Int,priceText: String,subtitle: String) -> Plan {
        .init(id: id,kind: .weekly, title: "Weekly", subtitle: subtitle, priceText: priceText, tagText: nil)
    }
    
    static func weeklyTrial(id: Int,priceText: String,subtitle: String) -> Plan {
        .init(id: id,kind: .weeklyTrial, title: "Weekly", subtitle: subtitle, priceText: priceText, tagText: nil)
    }
}



/// Tiny helper to unwrap StoreKit verification results
@inline(__always)
private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified(_, let error):
        throw error
    case .verified(let signedType):
        return signedType
    }
}

// MARK: - Manager

@MainActor
public final class ProSubscriptionManager: ObservableObject {

    // Public state you can bind to UI
    @Published var plans: [Plan] = []
    @Published public private(set) var yearly: Product?
    @Published public private(set) var weekly: Product?
    @Published public private(set) var weeklyTrial: Product?
    @Published public private(set) var yearlyPrice: String = ""
    @Published public private(set) var weeklyPrice: String = ""
    @Published public private(set) var weeklyTrialPrice: String = ""
    @Published public private(set) var isPro: Bool = false
    @Published public private(set) var proPlan: ProPlan?
    @Published public private(set) var isLoading: Bool = false
    
   

    public let yearlyID: String
    public let weeklyID: String
    public let weeklyTrialID: String

    private var updatesTask: Task<Void, Never>?

    // MARK: Init / lifecycle

    public init(yearlyID: String, weeklyID: String,weeklyTrialID: String) {
        self.yearlyID = yearlyID
        self.weeklyID = weeklyID
        self.weeklyTrialID = weeklyTrialID

        // Start background listener + initial load
        updatesTask = listenForTransactionUpdates()
     
        
       
    }

    deinit { updatesTask?.cancel() }

    // MARK: Public API

    /// Refresh products & prices (safe to call anytime).
    public func refreshProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let ids = Set([yearlyID, weeklyID,weeklyTrialID])
            let products = try await Product.products(for: ids)

            // assign
            for p in products {
                
                print("products are \(p.displayPrice)")
                if p.id == yearlyID { yearly = p; yearlyPrice = p.displayPrice }
                if p.id == weeklyID { weekly = p; weeklyPrice = p.displayPrice }
                if p.id == weeklyTrialID { weeklyTrial = p;weeklyTrialPrice = p.displayPrice}
            }
            
            

            if yearly == nil || weekly == nil || weeklyTrial == nil{
                let msg = "Some products were not found. Check Product IDs in App Store Connect."
                print(msg)
            }
            
            self.plans = [
                .yearly(id: 1, priceText: yearlyPrice, subtitle: "", tag: "save 90%"),
                .weekly(id: 2, priceText: weeklyPrice,subtitle: ""),
                .weeklyTrial(id: 3,priceText: weeklyTrialPrice,subtitle: "")
              ]
        } catch {
            let msg = "Failed to load products: \(error.localizedDescription)"
            print(msg)
        }
    }

    /// Purchase a plan. Returns true if a verified transaction completed.
    @discardableResult
    public func purchase(_ plan: ProPlan) async -> Bool {
        guard let product = product(for: plan) else {
            let msg = "Product not loaded."
            print(msg)
            return false
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                return true

            case .userCancelled, .pending:
                return false

            @unknown default:
                return false
            }
        } catch {
            let msg = "Purchase failed: \(error.localizedDescription)"
            print(msg)
            return false
        }
    }

    /// Trigger App Store restore; entitlements update via listener.
    public func restore() async {
        do {
            try await AppStore.sync()
            print("restore")
        }
        catch {
            let msg = "Restore failed: \(error.localizedDescription)"
            print(msg)
        }
        await refreshEntitlements()
    }

    /// Manually recompute the `isPro` flag from current entitlements.
    public func refreshEntitlements() async {
            let ids = [yearlyID, weeklyID]

            do {
                // ---- 1) Current entitlements (works iOS 15+) ----
                var active = false
                var seenAny = false

                var current: [Transaction] = []
                for await v in Transaction.currentEntitlements {
                    
                 
                    if let t = try? checkVerified(v) {
                        current.append(t)
                    }
                }
                seenAny = !current.isEmpty
                
                print("verify \(seenAny)")

                for t in current where ids.contains(t.productID) {
                    
                    
                    if (t.expirationDate ?? .distantFuture) > Date() {
                        print("verify here it is \(t.productID)")
                        active = true
                        if t.productID == yearlyID {
                            proPlan = .yearly
                        }else if t.productID == weeklyID{
                            proPlan = .weekly
                        }else if t.productID == weeklyTrialID{
                            proPlan = .weeklyTrial
                        }
                        break
                    }
                }

                // ---- 2) Fallback: latest(for:) per product ID ----
//                if !active {
//                    for id in ids {
//                        if let latest = try await Transaction.latest(for: id) {
//                            let t = try checkVerified(latest)
//                            if t.revocationDate == nil,
//                               (t.expirationDate ?? .distantFuture) > Date() {
//                                active = true
//                                break
//                            }
//                        }
//                    }
//                }

                // ---- 3) Optional: status(for:) (handles upgrades, family share) ----
//                if !active {
//                    let statuses: [Product.SubscriptionInfo.Status]
//                    if #available(iOS 17.2, *) {
//                        statuses = try await Product.SubscriptionInfo.status(for: "Yearly")
//                    } else {
//                        var tmp: [Product.SubscriptionInfo.Status] = []
//                        for id in ids {
//                            let s = try await Product.SubscriptionInfo.status(for: id)
//                            tmp.append(contentsOf: s)
//                        }
//                        statuses = tmp
//                    }
//
//                    for s in statuses where s.state == .subscribed {
//                        if let tx = try? checkVerified(s.transaction),
//                           tx.revocationDate == nil,
//                           (tx.expirationDate ?? .distantFuture) > Date() {
//                            active = true
//                            break
//                        }
//                    }
//                }
                
                print("active: \(active)")

                self.isPro = active
                if !seenAny && !active {
                    // Not an error; often first run or signed-out App Store
                    print("error 1")
                }
            } catch {
                self.isPro = false
                let msg = "Entitlement check failed: \(error.localizedDescription)"
                print(msg)
            }
        }

    // MARK: Private

    private func product(for plan: ProPlan) -> Product? {
        switch plan {
        case .yearly: return yearly
        case .weekly: return weekly
        case .weeklyTrial: return weeklyTrial
        }
    }

    private func candidateMatch(_ id: String) -> Bool {
        id == yearlyID || id == weeklyID || id == weeklyTrialID
    }

    /// Background listener updates `isPro` whenever a transaction changes.
    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                do {
                    let transaction = try checkVerified(update)
                    if await self!.candidateMatch(transaction.productID) {
                        await transaction.finish()
                        await self!.refreshEntitlements()
                    }
                } catch {
                    await MainActor.run {
                        let msg = "Update verify failed: \(error.localizedDescription)"
                        print(msg)
                    }
                }
            }
        }
    }
}
