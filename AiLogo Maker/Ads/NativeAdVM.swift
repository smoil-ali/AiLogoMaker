//
//  NativeAdVM.swift
//  Ai Image Art
//
//  Created by Apple on 11/10/2025.
//


import SwiftUI
import GoogleMobileAds

final class NativeAdVM: NSObject, ObservableObject, NativeAdLoaderDelegate, NativeAdDelegate {
    @Published var ad: NativeAd?
    private var adLoader: AdLoader!
    
    
    func loadOne(){
        
    }


    func loadRaza(){
        
    }

    func refreshAd() {
        
      var adId: String
      #if DEBUG
        adId = "ca-app-pub-3940256099942544/3986624511"
      #else
        adId = "ca-app-pub-5091329724527747/5954929015"
      #endif
        
      adLoader = AdLoader(
        adUnitID: adId,
        // The UIViewController parameter is optional.
        rootViewController: nil,
        adTypes: [.native], options: nil)
      adLoader.delegate = self
      adLoader.load(Request())
    }
    
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
      // Native ad data changes are published to its subscribers.
      self.ad = nativeAd
      nativeAd.delegate = self
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
      print("\(adLoader) failed with error: \(error.localizedDescription)")
    }
}


private extension UIApplication {
    func keyWindowTopVC(base: UIViewController? = UIApplication.shared
        .connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController { return keyWindowTopVC(base: nav.visibleViewController) }
        if let tab = base as? UITabBarController { return keyWindowTopVC(base: tab.selectedViewController) }
        if let presented = base?.presentedViewController { return keyWindowTopVC(base: presented) }
        return base
    }
}
