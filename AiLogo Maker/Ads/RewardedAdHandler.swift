//
//  RewardedAdHandler.swift
//  Ai Image Art
//
//  Created by Apple on 12/10/2025.
//


import SwiftUI
import GoogleMobileAds


@MainActor
final class RewardedAdHandler: NSObject, ObservableObject, FullScreenContentDelegate {
 

    private var continuation: CheckedContinuation<Bool, Never>?
    private var earned = false
    
    func loadShanza(){
        print("hello shanzah")
    }
    
    func login(){
        print("login added")
    }


    func loadRewardedAd(
        adId: String = "ca-app-pub-3940256099942544/1712485313"
    ) async -> RewardedAd? {
        
        
        return await withCheckedContinuation{ cont in
            
            
            
            let request = Request()
            RewardedAd.load(with: adId,
                               request: request) { ad, error in
                if let error = error {
                    print("Failed to load rewarded ad with error: \(error.localizedDescription)")
                    cont.resume(returning: nil)
                }
                
                if let rewardAd = ad{
                    rewardAd.fullScreenContentDelegate = self
                    cont.resume(returning: rewardAd)
                }
        

            }
        }

        
    }

    func presentRewardedAd(ad: RewardedAd?) async -> Bool {
        
        await withCheckedContinuation{ cont in
            
            if let ady = ad{
                continuation = cont
                ady.fullScreenContentDelegate = self
                
                ady.present(from: nil) { [weak self] in
                    self?.earned = true
                    self?.continuation?.resume(returning: true)
                }
                
                
            }else{
                continuation?.resume(returning: false)
            }
     
            
            
        }
        
    
  
    }

    
    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        print("Rewarded ad dismissed.")
        
        continuation?.resume(returning: earned)   // true if earned, else false
        continuation = nil
    }
    
    
    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        print("Rewarded ad failed to present with error: \(error.localizedDescription)")
        
        continuation?.resume(returning: false)
        continuation = nil
    }


    func adWillPresentFullScreenContent(_ ad: any FullScreenPresentingAd) {
        print("ads is present")
    }
    
    
}


