//
//  CommentDialog.swift
//  InvitationMaker
//
//  Created by Apple on 02/12/2025.
//

import Foundation
import Foundation
import SwiftUICore
import SwiftUI
struct CommentDialogView: ViewModifier {
    
    
    
    @Binding var isPresented: Bool
    let inputText: String
    let onDone: (String) -> Void
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

                    CommentView(
                        inputText: inputText,
                        onDone:onDone,
                        onCancel: onCancel
                    )
                    
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isPresented)
        }
    
    
}


struct CommentView: View {
    
    
    let inputText: String
    let onDone: (String) -> Void
    let onCancel: () -> Void

    @State var searchText: String = ""
    
    init(inputText: String,onDone: @escaping (String) -> Void,onCancel: @escaping () -> Void) {
        
        self.inputText = inputText
        self.onDone = onDone
        self.onCancel = onCancel
        _searchText = State(initialValue: inputText)
        
    }
    
    var body: some View {
        
        VStack(spacing: 20){
            
            
            
            TextField("",
                      text: $searchText,
                      prompt: Text("Enter your text")
                .foregroundColor(.black.opacity(0.5))
            )
            .autocapitalization(.none)
                .foregroundStyle(.black)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .lineLimit(5...10)
                .padding()
                .frame(height: 150,alignment: .top)
                .background(Color(hex: 0xEDEDED))
                .clipShape(.rect(cornerRadius: 16))
            
            
            HStack{
                
                
                Button(action: {
                    onCancel()
                },label: {
                    Text("Cancel")
                        .font(.title2)
                        .foregroundStyle(.black)
                        .padding()
                        .frame(maxWidth:.infinity,alignment: .center)
                        .background(Color(hex: 0xEDEDED))
                        .clipShape(.capsule)
                        
                })
                
                Button(action: {
                    if !searchText.isEmpty{
                        onDone(searchText)
                        
                    }
                },label: {
                    Text("Done")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth:.infinity,alignment: .center)
                        .background(Color(hex: 0x5E2F77))
                        .clipShape(.capsule)
                        
                })
            }
            
            
            
            
        }
        .padding(.horizontal)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .transition(.scale.combined(with: .opacity))
    }
}

extension View{
    func CommentDialog(isPresented: Binding<Bool>,
                       inputText: String,
                    onDone: @escaping (String) -> Void,
                    onCancel: @escaping () -> Void
                       ) -> some View {
        modifier(CommentDialogView(
            isPresented: isPresented,
            inputText: inputText,
            onDone: onDone,
            onCancel: onCancel
        ))
    }
}

#Preview {
    CommentView(inputText: "Hello",onDone: {_ in } ,onCancel: {})
}
