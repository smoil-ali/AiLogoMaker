//
//  AppOpenAdManager.swift
//  Ai Image Art
//
//  Created by Apple on 12/10/2025.
//


import GoogleMobileAds
import UIKit

class AppOpenAdManager: NSObject, FullScreenContentDelegate, ObservableObject {
    @Published var appOpenAd: AppOpenAd?
        var loadTime: Date?
        var isLoadingAd = false
    

        func loadAd() {
            guard !isLoadingAd && !isAdAvailable() else { return }
            isLoadingAd = true
            var adId: String
            #if DEBUG
              adId = "ca-app-pub-3940256099942544/5575463023"
            #else
              adId = "ca-app-pub-5091329724527747/8381720102"
            #endif

            AppOpenAd.load(with: adId, request: Request()) { ad, error in
                self.isLoadingAd = false
                if let error = error {
                    print("App open ad failed to load with error: \(error.localizedDescription)")
                    self.appOpenAd = nil
                    self.loadTime = nil
                    return
                }
                self.appOpenAd = ad
                self.appOpenAd?.fullScreenContentDelegate = self
                self.loadTime = Date()
            }
        }

        func showAdIfAvailable() {
            guard let ad = appOpenAd, let loadTime = loadTime, isAdAvailable() else {
                print("Ad not ready or not available.")
                loadAd() // Load a new ad if none is available
                return
            }

            // Present the ad on the root view controller
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                ad.present(from: rootVC)
            }
        }

        func isAdAvailable() -> Bool {
            // Check if the ad is loaded and not expired (e.g., within 4 hours)
            if let loadTime = loadTime {
                return Date().timeIntervalSince(loadTime) < 4 * 3600 // 4 hours
            }
            return appOpenAd != nil
        }

        // GADFullScreenContentDelegate methods
    
    func adWillPresentFullScreenContent(_ ad: any FullScreenPresentingAd) {
        print("App open ad presented.")
    }


    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
            print("App open ad dismissed.")
            self.appOpenAd = nil
            self.loadTime = nil
            loadAd() // Load a new ad for the next time
        }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
            print("App open ad failed to present with error: \(error.localizedDescription)")
            self.appOpenAd = nil
            self.loadTime = nil
            loadAd() // Load a new ad
        }
    }
