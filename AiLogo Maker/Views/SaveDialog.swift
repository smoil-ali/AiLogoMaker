//
//  SaveDialog.swift
//  InvitationMaker
//
//  Created by Apple on 02/12/2025.
//

import Foundation
import SwiftUICore
import SwiftUI
struct SaveDialogView: ViewModifier {
    
    
    
    @Binding var isPresented: Bool
    let onImage: () -> Void
    let onGif: () -> Void
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

                    DialogView(
                        onImage: onImage, onGif: onGif, onCancel: onCancel
                    )
                    
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isPresented)
        }
    
    
}


struct DialogView: View {
    
    let onImage: () -> Void
    let onGif: () -> Void
    let onCancel:() -> Void
    
    var body: some View {
        
        VStack(spacing: 10){
            
            Text("Alert")
                .frame(maxWidth: .infinity,alignment: .center)
                .foregroundStyle(.white)
                .font(.largeTitle)
            
            Button(action: {
                onImage()
            }, label: {
                
                Text("Save as Image")
                    .frame(maxWidth:.infinity,alignment: .center)
                    .foregroundStyle(Color(hex: 0x5E2F77))
                    .font(.title2)
                    .padding(.vertical,10)
                    .background(.white)
                    .clipShape(.capsule)
                    .padding(.horizontal)
            })
            
//            Button(action: {
//                onGif()
//            }, label: {
//                Text("Save as GIF")
//                    .frame(maxWidth:.infinity,alignment: .center)
//                    .foregroundStyle(Color(hex: 0x5E2F77))
//                    .font(.title2)
//                    .padding(.vertical,10)
//                    .background(.white)
//                    .clipShape(.capsule)
//                    .padding(.horizontal)
//                 
//            })
            
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
    func saveDialog(isPresented: Binding<Bool>,
                    onImage: @escaping () -> Void,
                    onGif: @escaping () -> Void,
                    onCancel: @escaping () -> Void
                       ) -> some View {
        modifier(SaveDialogView(
            isPresented: isPresented,
            onImage: onImage,
            onGif: onGif,
            onCancel: onCancel
        ))
    }
}

#Preview {
    DialogView(
        onImage:{},onGif: {},onCancel: {}
    )
}
