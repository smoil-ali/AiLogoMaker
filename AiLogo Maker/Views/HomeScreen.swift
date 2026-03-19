//
//  HomeScreen.swift
//  AiLogo Maker
//
//  Created by Apple on 24/02/2026.
//

import SwiftUI
import SDWebImageSwiftUI


private let rows = [
    GridItem(.flexible(), spacing: 0),
]

struct HomeScreen: View {
    
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
    @State private var searchText: String = ""
    
    var body: some View {
        
        ZStack{
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    
                    Header(title: "Ai Logo Generator",onProAction: {
                        router.push(Route.Premium)
                    })
                    
                    Divider()
                        .frame(maxWidth:.infinity)
                        .frame(height: 1)
                        .background(Color(hex: 0x11182766))
                    
                    Spacer(minLength: 10)
                    
                    
                    AiContainerView(onAiAction: {
                        router.push(Route.AI)
                    })
                    
                    Spacer(minLength: 10)
                    
                    SearchField(searchText: $searchText)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                    
                    Spacer(minLength: 10)
                    
                    
                    if !vm.categories.isEmpty{
                        
                        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                        let categories: [CategoryData] = {
                            if query.isEmpty {
                                return vm.categories    // return all
                            }
                            return vm.categories.filter { $0.name.lowercased().contains(query) }
                        }()
                        
                        
                        ForEach(categories) { categoryData in
                            TemplateContainer(
                                value: categoryData.value,
                                title: categoryData.name,
                                totalItems: categoryData.total_item,
                                actionSeeAll: { value,title,totalItems in
                                    
                                    router.push(Route.SeeAll(value, title, totalItems))
                                    
                                }, action: { value, index in
                                    
                                    startDownloading(value: value, index: index)
                                    
                                }
                            )
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
                
                print("here loading is \(loading)")
                
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

struct Header: View {
    let title: String
    let onProAction: () -> Void
    var body: some View {
        HStack{
            
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color(hex: 0x111827))
            
            Spacer()
            
            
            Button(action: {
                onProAction()
            }) {
                
                HStack{
                    
                    Image("crown_icon")
                        .resizable()
                        .frame(width: 15,height: 15)
                        .scaledToFit()
                    
                    Text("Get Pro")
                        .fontWeight(.regular)
                        .padding(.vertical,1)
                    
                   
                }
                .padding(.horizontal)
                .padding(.vertical,7)
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
                
                

            }
            
            
            
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        
        
    }
}

private struct AiContainerView: View {
    
    let onAiAction: () -> Void
    var body: some View {
        ZStack{
            
            Image("banner_icon")
                .resizable()
                .padding(.horizontal)
                .frame(maxWidth:.infinity)
                .scaledToFill()
            
            Spacer()
            
            HStack{
                
                HStack{
                    
                    Text("Create with AI")
                        .foregroundStyle(.white)
                        .font(.system(size: 20))
                        .fontWeight(.semibold)
                    
                    Image("star_icon")
                        .scaledToFit()
                }
              
                
                
                Spacer()
                
                Button(action: {
                    onAiAction()
                }) {
                    
                    HStack{
                        
                        
                        Text("Get Pro")
                            .fontWeight(.regular)
                            .padding(.vertical,1)
                        
                       
                    }
                    .padding(.horizontal)
                    .padding(.vertical,5)
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
                    
                    

                }
                
                
                
            }
            .padding(.horizontal)
            .padding(.vertical,10)
            .frame(maxWidth:.infinity)
            .background(Color(hex: 0xF2F6FF).opacity(0.2))
            .clipShape(.capsule)
            .frame(maxHeight:.infinity,alignment: .bottom)
            .padding(.horizontal,35)
            .padding(.bottom,15)
          
          
            
            
        }
        .frame(height: 200)
    }
}


struct SearchField: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 0) {
            HStack {
              
                TextField("Search...",
                          text: $searchText,
                          prompt: Text("Search")
                    .foregroundColor(Color(hex: 0x111827).opacity(0.5))
                )
                .autocapitalization(.none)
                .foregroundColor(Color(hex: 0x111827).opacity(0.5))
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                
                
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(hex: 0x111827))
            }
            .padding(.vertical, 12)
            .padding(.leading)
            .padding(.trailing)
            .background(Color(hex: 0xD7DDEC))
            .clipShape(.capsule)
            

          
        }
        .frame(height: 44)
    }
}

struct TemplateContainer: View {
    
    let value: String
    let title: String
    let totalItems: Int
    
    let actionSeeAll: (String,String,Int) -> Void
    
    let action:(String,Int) -> Void
    
    
    var body: some View {
        
        VStack{
            HStack {
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: 0x111827))
                
                Spacer()
                
                Text("See All")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: 0x111827))
                    .onTapGesture {
                        actionSeeAll(value, title, totalItems)
                    }
                
            }
            .padding(.horizontal)
            .frame(maxWidth:.infinity)
            
        
            ScrollView(.horizontal, showsIndicators: false){
                
                LazyHGrid(rows: rows,spacing: 0) {
                    
                    
                    ForEach(0..<totalItems, id: \.self){ index in
                        
                        
                        
                        
                        TemplateCard(url: "https://firebasestorage.googleapis.com/v0/b/logo-maker-app-60097.firebasestorage.app/o/v2%2Ftemplates%2F\(value)%2Fthumbnails%2F\(index+1).png?alt=media&token=90a09bab-3d37-4453-9a03-39c938a9aa23",
                                     onAction: {
                            
                            action(value,index+1    )
                            
                                        })
                        
                    }
                    
                    
                }
               
            }
            .frame(maxWidth:.infinity)
            .frame(height: 125)
            
         
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
                        .scaledToFit()
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
                .padding(.horizontal, 16)
            }
        }
    }
}

#Preview {
    HomeScreen()
}
