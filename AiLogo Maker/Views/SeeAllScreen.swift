//
//  SeeAllScreen.swift
//  AiLogo Maker
//
//  Created by Apple on 07/03/2026.
//

import SwiftUI
import SDWebImageSwiftUI


private let columns = [
    GridItem(.flexible(), spacing: 0),
    GridItem(.flexible(), spacing: 0),
    GridItem(.flexible(), spacing: 0)
]
struct SeeAllScreen: View {
    
    @Environment(\.dismiss) var dismiss
    let value: String
    let title: String
    let totalItems: Int
    @State private var templateDownloading: Bool = false
    @StateObject private var vm = DataRepo.shared
    @EnvironmentObject var router: NavigationRouter
    
    var body: some View {
        VStack{
            
            HeaderWithBack(title: title,onProAction: {
                
            },onBackAction: { dismiss() })
            
            Divider()
                .frame(maxWidth:.infinity)
                .frame(height: 1)
                .background(Color(hex: 0x11182766))
            
            ScrollView{
                
                
                LazyVGrid(columns: columns,spacing: 10) {
                    
            
                    
                    ForEach(0..<totalItems, id: \.self){ index in
                        
                        let url = "https://firebasestorage.googleapis.com/v0/b/logo-maker-app-60097.firebasestorage.app/o/v2%2Ftemplates%2F\(value)%2Fthumbnails%2F\(index+1).png?alt=media&token=90a09bab-3d37-4453-9a03-39c938a9aa23"
                        
                        TemplateCard(url: url, onAction: {
                            startDownloading(value: value, index: index+1)
                        })
                    }
                }
                
            }
            
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity)
        .background(.white)
    }
    
    private func startDownloading(value: String,index: Int) {
        

        Task{
            
            do{
                
                templateDownloading = true
                
                
                try await vm.downloadJsonOfTemplate(value: value, position: index)
                try await vm.downloadAssetsOfTemplate(value: value, position: index)
                
                
                
                await TemplateHandler.shared.start(value: value, position: index)
                
                templateDownloading = false
                
                
                router.push(Route.TemplateScreen)
                
            
           
            }catch{
                templateDownloading = false
                print("error \(error.localizedDescription)")
            }
      
        }
    }
}

private struct TemplateCard: View {
    
    var url = ""
    @State var isLoading = true
    let onAction: () -> Void
    
    init(url: String, onAction: @escaping () -> Void) {
        self.url = url
        self.onAction = onAction
    }
    
    var body: some View {
        VStack(spacing: 8) {
            
            ZStack(alignment: .topLeading) {
                WebImage(url: URL(string: url)) { image in
                    
              
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 5)
                        .onTapGesture {
                            onAction()
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
                .padding(.horizontal,10)
            }
        }
    }
}


struct HeaderWithBack: View {
    let title: String
    let onProAction: () -> Void
    let onBackAction: () -> Void
    var body: some View {
        HStack{
            
            Image(systemName: "arrow.backward")
                .scaledToFit()
                .foregroundStyle(Color(hex: 0x111827))
                .onTapGesture {
                    onBackAction()
                }
            
            Spacer()
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color(hex: 0x111827))
            
            Spacer()
            
            
            
            
            
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        
        
    }
    
    
}

#Preview {
    SeeAllScreen(value: "", title: "", totalItems: 0)
}
