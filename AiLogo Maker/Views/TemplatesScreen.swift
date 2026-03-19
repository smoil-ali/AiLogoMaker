//
//  TemplatesScreen.swift
//  AiLogo Maker
//
//  Created by Apple on 25/02/2026.
//

import SwiftUI
import SDWebImageSwiftUI


private let columns = [
    GridItem(.flexible(), spacing: 0),
    GridItem(.flexible(), spacing: 0),
    GridItem(.flexible(), spacing: 0)
]
struct TemplatesScreen: View {
    
    @EnvironmentObject var router: NavigationRouter
    @StateObject private var vm = DataRepo.shared
    @State private var loading: Bool = false
    @State private var templateDownloading: Bool = false
    @State private var showAlert = false
    @State private var message: String = ""
    @State private var triggerFeedback = false
    @State private var value: String = ""
    @State private var position: String = ""
    @State private var name: String = ""
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack{
            
            VStack(alignment: .leading, spacing: 16) {
                
                Header(title: "Templates",onProAction: {
                    router.push(Route.Premium)
                })
                
                Divider()
                    .frame(maxWidth:.infinity)
                    .frame(height: 1)
                    .background(Color(hex: 0x11182766))
                
                
                if !vm.categories.isEmpty {
                    VStack{
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack{
                                
                                ForEach(vm.categories, id: \.id) { item in
                                    
                                    Button(action: {
                                        withAnimation {
                                            selectedTab = tabIndex(item.name)
                                        }
                                    }) {
                                        
                                        HStack{
                                            
                                            
                                            Text(item.name)
                                                .fontWeight(.regular)
                                                .padding(.vertical,1)
                                                .foregroundStyle(.white)
                                            
                                           
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical,5)
                                        .background(
                                            selectedTabTitle(item.name) ? LinearGradient(colors: [Color(hex: 0x00FFF0),
                                                                    Color(hex: 0x7B2FF7),
                                                                    Color(hex: 0xFF3CAC)
                                                                   ],
                                                           startPoint: .leading,
                                                                                        endPoint: .trailing) :
                                                LinearGradient(colors: [Color(hex: 0xC4D0E1)
                                                                       ],
                                                               startPoint: .leading,
                                                                                            endPoint: .trailing)
                                                
                                        )
                                        .foregroundColor(.white)
                                        .clipShape(.capsule)
                                        
                                        

                                    }
                                    
                                    
                                }
                                
                            }
                            .padding(.horizontal,16)
                        }
                        
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            
                            
                            LazyVGrid(columns: columns,spacing: 10) {
                                
                                let categoryData = vm.categories[selectedTab]
                                
            
                                let totalItems = Int(categoryData.total_item)
                                let value = categoryData.value
                                
                                ForEach(0..<totalItems, id: \.self){ index in
                                    
                                    let url = "https://firebasestorage.googleapis.com/v0/b/logo-maker-app-60097.firebasestorage.app/o/v2%2Ftemplates%2F\(value)%2Fthumbnails%2F\(index+1).png?alt=media&token=90a09bab-3d37-4453-9a03-39c938a9aa23"
                                    
                                    TemplateCard(url: url, onAction: {
                                        startDownloading(value: value, index: index+1)
                                    })
                                }
                            }
                            
                        }
                        
                        
                        
                        
                        
                    }
                }
                
                
                
                
                
            }
            
        }
        .frame(maxWidth:.infinity,maxHeight: .infinity)
        .background(.white)
        .loadingDialog(isPresented: $loading,message: "Please wait...")
        .loadingDialog(isPresented: $templateDownloading,message: "loading...")
        .alert("Alert", isPresented: $showAlert, actions: {
            Button("Ok", action: {
                showAlert = false
            })
        }, message: {
            Text(message)
        })
        .onAppear {
            
            Task {
                loading = true
                await vm.initialize()
                loading = false
            }
                
        }
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
    
    private func tabIndex(_ title: String) -> Int {
        
        vm.categories.count == 0 ? 0 : vm.categories.firstIndex(where: {item in item.name == title}) ?? 0
    }

    private func selectedTabTitle(_ title: String) -> Bool {
        return tabIndex(title) == selectedTab
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


#Preview {
    TemplatesScreen()
}
