//
//  InterstitialAd.swift
//  InvitationMaker
//
//  Created by Apple on 15/12/2025.
//

import Foundation
import GoogleMobileAds

class InterstitialViewModel: NSObject, FullScreenContentDelegate {
  private var interstitialAd: InterstitialAd?

  func loadAd() async {
    do {

        var adId: String
        #if DEBUG
          adId = "ca-app-pub-3940256099942544/4411468910"
        #else
          adId = "ca-app-pub-5091329724527747/623026118"
        #endif
        
        
        if interstitialAd == nil {
            
            interstitialAd = try await InterstitialAd.load(
              with: adId, request: Request())
        }
        
    
      // [START set_the_delegate]
      interstitialAd?.fullScreenContentDelegate = self
      // [END set_the_delegate]
    } catch {
      print("Failed to load interstitial ad with error: \(error.localizedDescription)")
    }
  }
 
  func showAd() {
    guard let interstitialAd = interstitialAd else {
      return print("Ad wasn't ready.")
    }

    interstitialAd.present(from: nil)
  }
  // [END show_ad]

  // MARK: - GADFullScreenContentDelegate methods

  // [START ad_events]
  func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
    print("\(#function) called")
  }

  func adDidRecordClick(_ ad: FullScreenPresentingAd) {
    print("\(#function) called")
  }

  func ad(
    _ ad: FullScreenPresentingAd,
    didFailToPresentFullScreenContentWithError error: Error
  ) {
    print("\(#function) called")
  }

  func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
    print("\(#function) called")
  }

  func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
    print("\(#function) called")
  }

  func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
    print("\(#function) called")
    // Clear the interstitial ad.
    interstitialAd = nil
 
  }
  // [END ad_events]
}
