//
//  NativeAdSlot.swift
//  Ai Image Art
//
//  Created by Apple on 11/10/2025.
//

import SwiftUI

struct NativeAdSlot: View {
    @StateObject private var vm = NativeAdVM()
    let kind: NativeTemplateKind

    var body: some View {
        Group {
            if let ad = vm.ad {
                NativeTemplateView(nativeViewModel: vm)
                    .frame(maxHeight: .infinity)
                    .shadow(radius: 4)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.thinMaterial)
                    .frame(maxHeight: .infinity)
                    .overlay(Text("Ad").font(.caption).foregroundColor(.secondary))
            }
        }
        .onAppear { vm.refreshAd() }
    }
}
