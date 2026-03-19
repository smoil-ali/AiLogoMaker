//
//  GIFWebView.swift
//  AiLogo Maker
//
//  Created by Apple on 08/03/2026.
//


import SwiftUI
import WebKit

struct GIFWebView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let asset = NSDataAsset(name: gifName) else {
            
            print("null in the house")
            return
        }
        
        print("here it is")
        uiView.load(asset.data, mimeType: "image/gif", characterEncodingName: "UTF-8", baseURL: Bundle.main.resourceURL!)
        uiView.backgroundColor = .clear
    }
}