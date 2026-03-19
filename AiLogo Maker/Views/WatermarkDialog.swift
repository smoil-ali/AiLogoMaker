//
//  WatermarkDialog.swift
//  InvitationMaker
//
//  Created by Apple on 15/12/2025.
//

//
//  SaveDialog.swift
//  InvitationMaker
//
//  Created by Apple on 02/12/2025.
//

import Foundation
import SwiftUICore
import SwiftUI
struct WatermarkDialogView: ViewModifier {
    
    
    
    @Binding var isPresented: Bool
    let showReward: Bool
    let onPremium: () -> Void
    let onAd: () -> Void
    let onCancel:() -> Void
    
    
    func body(content: Content) -> some View {
            ZStack {
                content
                    .disabled(isPresented)

                if isPresented {
                    // Scrim
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    WatermarkDialog(
                        showReward: showReward,onPremium: onPremium, onAd: onAd, onCancel: onCancel
                    )
                    
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isPresented)
        }
    
    
}


struct WatermarkDialog: View {
    
    let showReward: Bool
    let onPremium: () -> Void
    let onAd: () -> Void
    let onCancel:() -> Void
    
    var body: some View {
        
        VStack(spacing: 10){
            
            Text("Alert")
                .frame(maxWidth: .infinity,alignment: .center)
                .foregroundStyle(.white)
                .font(.largeTitle)
            
            Button(action: {
                onPremium()
            }, label: {
                
                Text("Buy Premium")
                    .frame(maxWidth:.infinity,alignment: .center)
                    .foregroundStyle(Color(hex: 0x5E2F77))
                    .font(.title2)
                    .padding(.vertical,10)
                    .background(.white)
                    .clipShape(.capsule)
                    .padding(.horizontal)
            })
            
            
            if showReward{
                Button(action: {
                    onAd()
                }, label: {
                    Text("Watch Ad")
                        .frame(maxWidth:.infinity,alignment: .center)
                        .foregroundStyle(Color(hex: 0x5E2F77))
                        .font(.title2)
                        .padding(.vertical,10)
                        .background(.white)
                        .clipShape(.capsule)
                        .padding(.horizontal)

                })
            }
            
   
            
            Button(action: {
                onCancel()
            }, label: {
                Text("Cancel")
                    .frame(maxWidth:.infinity,alignment: .center)
                    .foregroundStyle(Color(hex: 0x5E2F77))
                    .font(.title2)
                    .padding(.vertical,10)
                    .background(.white)
                    .clipShape(.capsule)
                    .padding(.horizontal)
                 
            })
            
            
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: 0x5E2F77))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(40)
        .transition(.scale.combined(with: .opacity))
    }
}

extension View{
    func watermarkDialog(isPresented: Binding<Bool>,
                         showReward: Bool,
                    onPremium: @escaping () -> Void,
                    onAd: @escaping () -> Void,
                    onCancel: @escaping () -> Void
                       ) -> some View {
        modifier(WatermarkDialogView(
            isPresented: isPresented,
            showReward: showReward,
            onPremium: onPremium,
            onAd: onAd,
            onCancel: onCancel
        ))
    }
}



