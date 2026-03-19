//
//  ContentView.swift
//  AiLogo Maker
//
//  Created by Apple on 24/02/2026.
//

import SwiftUI

struct ContentView: View {
    
    @AppStorage("showOnBoarding") private var showOnBoarding = true
    @EnvironmentObject var router: NavigationRouter
    
    var body: some View {
        NavigationStack(path: $router.path){
            Group{
                if showOnBoarding{
                    OnBoardingScreen()
                        .navigationBarHidden(true)
                }else{
                    MainScreen()
                        .navigationBarHidden(true)
                }
            }.navigationDestination(for: Route.self){ route in
                
                switch route {
                case .Main:
                    MainScreen()
                        .navigationBarHidden(true)
                case .OnBoarding:
                    OnBoardingScreen()
                        .navigationBarHidden(true)
                case .TemplateScreen:
                    NewTemplateEditor(template: TemplateHandler.shared.template!)
                        .navigationBarHidden(true)
                case .Create:
                    CreateInvitation()
                        .navigationBarHidden(true)
                case .SeeAll(let value,let title,let totoalItems):
                    SeeAllScreen(value: value,
                                 title: title,
                                 totalItems: totoalItems
                    )
                    .navigationBarHidden(true)
                case .AI:
                    AiScreen()
                        .navigationBarHidden(true)
                case .Generate(let url):
                    GenerativeAi(url: url)
                        .navigationBarHidden(true)
                case .Premium:
                    ChrismasPremium()
                        .navigationBarHidden(true)
                default: EmptyView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
