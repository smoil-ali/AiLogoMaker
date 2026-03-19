//
//  BannerAdImpl.swift
//  Ai Image Art
//
//  Created by Apple on 11/10/2025.
//

import Foundation
import SwiftUI
import GoogleMobileAds

struct BannerViewContainer: UIViewRepresentable {
    
    
    let adSize: AdSize
    
    init(_ adSize: AdSize) {
      self.adSize = adSize
    }
    
    func makeUIView(context: Context) -> BannerView {
      let banner = BannerView(adSize: adSize)
      #if DEBUG
      banner.adUnitID = "ca-app-pub-3940256099942544/2435281174"
      #else
      banner.adUnitID = "ca-app-pub-5091329724527747/8581092354"
      #endif
      banner.load(Request())
      banner.delegate = context.coordinator
      return banner
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {}

     func makeCoordinator() -> BannerCoordinator {
       return BannerCoordinator(self)
     }
    
    class BannerCoordinator: NSObject, BannerViewDelegate {

      let parent: BannerViewContainer

      init(_ parent: BannerViewContainer) {
        self.parent = parent
      }

      // MARK: - GADBannerViewDelegate methods

      func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("DID RECEIVE AD.")
      }

      func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("FAILED TO RECEIVE AD: \(error.localizedDescription)")
      }
    }
}
