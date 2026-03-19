//
//  AiScreen.swift
//  AiLogo Maker
//
//  Created by Apple on 09/03/2026.
//

import SwiftUI

struct AiScreen: View {
    
    
    @EnvironmentObject var router: NavigationRouter
    @Environment(\.dismiss) var dismiss
    @State private var prompt: String = ""
    @State private var message: String = ""
    @State private var loading: Bool = false
    @State private var showAlert: Bool = false
    
    @FocusState private var isPromptFocused: Bool
    
    var body: some View {
        VStack{
            
            HeaderWithBack(title: "Create Logo", onProAction: {
                
            }, onBackAction: {
                dismiss()
            })
            
            Divider()
                .frame(maxWidth:.infinity)
                .frame(height: 1)
                .background(Color(hex: 0x11182766))
            
            ScrollView{
                
                Text("Enter Description")
                    .foregroundStyle(Color(hex: 0x111827))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth:.infinity,alignment: .leading)
                    .padding(.horizontal)
                
                TextField("", text: $prompt, prompt: Text("Type here")
                    .foregroundColor(Color(hex: 0x6F6F6F)), axis: .vertical)
                    .lineLimit(7...9)
                    .foregroundStyle(Color(hex: 0x6F6F6F))
                    .font(.system(size: 16,weight: .regular))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color(hex: 0xD7DDEC))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.top)
                    .padding(.horizontal)
                
                Spacer(minLength:20)
                
                
                GenerateButton(onAction: {
                    
                    if !prompt.isEmpty {
                        Task {
                            
                            do {
                                
                                loading = true
                                let taskId = try await FluxClient.shared.generateImage(
                                    apiKey: "f71deef59747d4d1cc0cddee899f7927",
                                    prompt: prompt,
                                    aspectRatio: "16:9"
                                )
                                
                                print("Task ID:", taskId)
                                
                             
                                
                                var imageUrl: String? = nil

                                while imageUrl == nil {
                                    
                                    do {
                                        imageUrl = try await FluxClient.shared.fetchImage(
                                            apiKey: "f71deef59747d4d1cc0cddee899f7927",
                                            taskId: taskId
                                        )
                                        
                                        if imageUrl == nil {
                                            try await Task.sleep(nanoseconds: 1_000_000_000) // wait 2 seconds
                                        }
                                        
                                    } catch {
                                        print("Fetch error:", error)
                                        break
                                    }
                                }

                                print("Image URL:", imageUrl ?? "Not generated")
                        
                           
                                
                                loading = false
                                print("Image URL:", imageUrl ?? "Not ready yet")
                                
                                router.push(Route.Generate(imageUrl ?? ""))
                                
                            } catch {
                                loading = false
                                message = error.localizedDescription
                                showAlert = true
                                print("Error:", error)
                            }
                        }
                    }
                    
               
                    
                })
                    
                
                
            }
            
        }
        .frame(maxWidth:.infinity,maxHeight: .infinity)
        .background(.white)
        .loadingDialog(isPresented: $loading,message: "loading...")
        .alert("Alert", isPresented: $showAlert, actions: {
            Button("Ok", action: {
                showAlert = false
            })
        }, message: {
            Text(message)
        })
    }
}

private struct GenerateButton: View {
    let onAction: () -> Void
    var body: some View {
        Button(action: {
            onAction()
        }) {
            
            HStack{
                
                Image("star_icon")
                    .scaledToFit()
                
                Text("Generate")
                    .fontWeight(.semibold)
                    .font(.title3)
                    .padding(.vertical,1)
                
                
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(colors: [Color(hex: 0x00FFF0),
                                        Color(hex: 0x7B2FF7),
                                        Color(hex: 0xFF3CAC)
                                       ],
                               startPoint: .leading,
                               endPoint: .trailing)
            )
            .foregroundColor(.white)
            .clipShape(.capsule)
            .padding(.horizontal)
            
            
            
        }
    }
}

#Preview {
    AiScreen()
}
