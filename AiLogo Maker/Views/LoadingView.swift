//
//  LoadingView.swift
//  InvitationMaker
//
//  Created by Apple on 27/11/2025.
//

import SwiftUI

struct LoadingView: ViewModifier {
    
    
    
    @Binding var isPresented: Bool
    var title: String? = "Please wait…"
    var message: String? = nil
    var cancellable: Bool = false
    var cancelTitle: String = "Cancel"
    var onCancel: (() -> Void)? = nil
    
    func body(content: Content) -> some View {
            ZStack {
                content
                    .disabled(isPresented)

                if isPresented {
                    // Scrim
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    // Card
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.2)

                        if let title {
                            Text(title)
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        if let message, !message.isEmpty {
                            Text(message)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.75))
                                .multilineTextAlignment(.center)
                        }

                        if cancellable {
                            Button {
                                onCancel?()
                            } label: {
                                Text(cancelTitle)
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(.white.opacity(0.14), in: Capsule())
                            }
                            .padding(.top, 6)
                        }
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
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isPresented)
        }
    
    
}


extension View{
    func loadingDialog(isPresented: Binding<Bool>,
                       title: String? = "Please wait…",
                       message: String? = nil,
                       cancellable: Bool = false,
                       cancelTitle: String = "Cancel",
                       onCancel: (() -> Void)? = nil) -> some View {
        modifier(LoadingView(isPresented: isPresented,
                                       title: title,
                                       message: message,
                                       cancellable: cancellable,
                                       cancelTitle: cancelTitle,
                                       onCancel: onCancel))
    }
}
