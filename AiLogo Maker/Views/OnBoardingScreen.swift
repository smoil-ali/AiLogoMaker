//
//  OnBoardingScreen.swift
//  AiLogo Maker
//
//  Created by Apple on 24/02/2026.
//

import SwiftUI

struct OnBoardingScreen: View {
    
    @EnvironmentObject var router: NavigationRouter
    @AppStorage("showOnBoarding") private var showOnBoarding = true
    var list: [OnBoardData] = []
    @State private var page = 0
    
    init() {
        let item1 = OnBoardData(image: "onboard_1",
                                title: "Create Logos with AI",
                                description: "Transform ideas into stunning logos instantly with intelligent AI creativity.",
                                optionalDescription: ""
        )
        
        let item2 = OnBoardData(image: "onboard_2",
                                title: "Edit & Perfect Your Design",
                                description: "Change colors, fonts, and icons effortlessly to match your brand style.",
                                optionalDescription: ""
        )
        
        list.append(item1)
        list.append(item2)
        
        
    }
    var body: some View {
        
        ZStack {
            
            TabView(selection: $page) {
                ForEach(list.indices, id: \.self) { idx in
                    OnboardingCard(item: list[idx],action: {
                        if page < list.count - 1 {
                            page += 1
                        }else{
                            
                            showOnBoarding = false
                            router.resetAndPush(Route.Main)
                           
                        }
                    })
                    .tag(idx)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)
            .ignoresSafeArea(.all)
            
        }
    }
}

struct OnboardingCard: View {
    let item: OnBoardData
    let action: () -> Void
   
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Full-bleed image

                VStack{
                    
                    
                    Text(item.title)
                        .font(.title.weight(.heavy))
                        .foregroundStyle(Color(hex: 0x5E2F77))
                        .multilineTextAlignment(.center)
                    
               
                    Text(item.description)
                        .font(.body)
                        .foregroundStyle(Color(hex: 0x6B6B6B))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    StartButton(onAction: {
                        action()
                    })
                }
                .frame(maxHeight:.infinity,alignment: .bottom)
            }
            .frame(maxWidth:.infinity,maxHeight: .infinity)
            .background{
                
                Image(item.image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
         
            
        }
      
    }
}

private struct StartButton: View {
    let onAction: () -> Void
    var body: some View {
        Button(action: {
            onAction()
        }) {
            
            HStack{
                
                Text("Continue")
                    .fontWeight(.regular)
                    .padding(.vertical,1)
                
                Image(systemName: "arrow.right")
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
    OnBoardingScreen()
}

struct OnBoardData: Identifiable{
    let id = UUID()
    let image: String
    let title: String
    let description: String
    let optionalDescription: String
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xff)/255
        let g = Double((hex >> 8) & 0xff)/255
        let b = Double(hex & 0xff)/255
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
