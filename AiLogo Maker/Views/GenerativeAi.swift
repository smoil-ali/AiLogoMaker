//
//  GenerativeAi.swift
//  AiLogo Maker
//
//  Created by Apple on 11/03/2026.
//

import SwiftUI
import SDWebImageSwiftUI

struct GenerativeAi: View {
    
    @Environment(\.dismiss) var dismiss
    @State var isLoading = true
    @State var loading = false
    @State var showAlert = false
    @State var message = ""
    
    let url: String
    var body: some View {
        VStack{
            
            HeaderWithBack(title: "Download", onProAction: {
                
            }, onBackAction: {
                dismiss()
            })
            
            Divider()
                .frame(maxWidth:.infinity)
                .frame(height: 1)
                .background(Color(hex: 0x11182766))
            
            WebImage(url: URL(string: url)) { image in
                
          
                image
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 5)
                    .onTapGesture {
                        
                    }
                    .onAppear{
                        isLoading = false
                    }
                    .padding(.vertical,5)
            } placeholder: {
                
                
              
                ProgressView()
                    .tint(.black)
                    .onAppear{
                        isLoading = true
                    }
            }
            .onSuccess { image, data, cacheType in
            }
            .indicator(.activity) // Activity Indicator
            .transition(.fade(duration: 0.5)) // Fade Transition with duration
            .scaledToFit()
            .padding(.horizontal, 16)
            
            DownloadButton(title: "Download", onProAction: {
                Task {
                    
                    isLoading = true
                    let image = await download()
                    if let img = image{
                        FileUtils.shared.saveImageToPhotos(img, completion: { status in
                            
                            switch status {
                            case .success:
                                showAlert = true
                                message = "Image downloaded successfully"
                                break
                                
                            case .failure:
                                showAlert = true
                                message = "Image download failed"
                                break
                            }
                        })
                    }
                    isLoading = false
                
                }
            })
            
            
            
            
        }
        .loadingDialog(isPresented: $loading,message: "Please wait...")
        .alert("Alert", isPresented: $showAlert, actions: {
            Button("Ok", action: {
                showAlert = false
            })
        }, message: {
            Text(message)
        })
        .frame(maxWidth:.infinity,maxHeight: .infinity,alignment: .top)
        .background(.white)
    }
    
    private func download() async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)
            guard let image = UIImage(data: data) else { throw URLError(.cannotDecodeRawData) }
            return image
        } catch {
            return nil
        }
    }
}

private struct DownloadButton: View {
    let title: String
    let onProAction: () -> Void
    var body: some View {
        
        Button(action: {
            onProAction()
        }) {
            
            HStack{
                
                Image(systemName: "arrow.down")
                    .resizable()
                    .frame(width: 15,height: 15)
                    .scaledToFit()
                
                Text("Download")
                    .fontWeight(.regular)
                    .padding(.vertical,1)
                
               
            }
            .padding(.horizontal)
            .padding(.vertical,7)
            .frame(maxWidth:.infinity)
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
    GenerativeAi(url: "")
}
