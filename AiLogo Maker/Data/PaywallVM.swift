//
//  PaywallVM.swift
//  Ai Image Art
//
//  Created by Apple on 04/10/2025.
//

import Foundation


@MainActor
final class PaywallVM: ObservableObject {
    
    
    
    let manager = ProSubscriptionManager(yearlyID: "year.id", weeklyID: "week.id",weeklyTrialID: "trial.week.id")
    
    // Mirror what the UI needs (these WILL trigger view updates)
    @Published var isPro = false
    @Published var yearlyPrice = ""
    @Published var weeklyPrice = ""
    @Published var weeklyTrialPrice = ""
    @Published var lastError: String?
    @Published var proPlan: ProPlan?
    
    
    
    init() {
        // forward nested changes -> this VM
        manager.$isPro
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPro)
        manager.$proPlan
            .receive(on: DispatchQueue.main)
            .assign(to: &$proPlan)
        
        manager.$yearlyPrice
            .receive(on: DispatchQueue.main)
            .assign(to: &$yearlyPrice)
        
        manager.$weeklyPrice
            .receive(on: DispatchQueue.main)
            .assign(to: &$weeklyPrice)
        manager.$weeklyTrialPrice
            .receive(on: DispatchQueue.main)
            .assign(to: &$weeklyTrialPrice)
        
        
    }
    
    
    
    func buyYearly() async -> Bool{
        print("purchase successfull")
        return true
    }
    
    func buyQuarter() async -> Bool{
        print("purchase successfull")
        return true
    }
    
    
    
    func buyMonthly() async -> Bool{
        return await manager.purchase(.yearly)
    }
    func buyWeekly() async -> Bool {
        return await manager.purchase(.weekly)
    }
    func buyWeeklyTrial() async -> Bool {
        return await manager.purchase(.weeklyTrial)
    }
    func restore()    async { await manager.restore() }
}
