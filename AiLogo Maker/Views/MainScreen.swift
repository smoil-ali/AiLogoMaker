//
//  MainScreen.swift
//  AiLogo Maker
//
//  Created by Apple on 24/02/2026.
//

import SwiftUI

enum Tabs: CaseIterable {
    case home,templates,history,settings        /*, chart, people, ai*/
    
    var sfSymbol: String {
        switch self {
        case .home:  return "home_icon"
        case .templates: return "templates_icon"
        case .history:   return "history_icon"
        case .settings: return "settings_icon"
            
        }
    }
}

struct MainScreen: View {
    
    @State private var selection: Tabs = .home
    
    var body: some View {
        ZStack{
            TabView(selection: $selection) {
                HomeScreen()
                    .tag(Tabs.home)
                
                TemplatesScreen()
                    .tag(Tabs.templates)
                
                HistoryScreen()
                    .tag(Tabs.history)
                
                SettingsScreen()
                    .tag(Tabs.settings)
                
            }
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                CustomTabBar(selection: $selection)
            }
            .ignoresSafeArea(.keyboard)
        }
        .frame(maxWidth:.infinity,maxHeight: .infinity)
        .background(Color(hex: 0xF2F6FF))
        .ignoresSafeArea()
    }
}

struct CustomTabBar: View {
    
    @Binding var selection: Tabs
    @EnvironmentObject var router: NavigationRouter
    var body: some View {
        HStack{
            
            Spacer()
            
            VStack(spacing: 7){
                
                Image("home_icon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundStyle(
                        selection == .home ?
                        LinearGradient(colors: [
                            Color(hex: 0x00FFF0),
                            Color(hex: 0x7B2FF7),
                            Color(hex: 0xFF3CAC)
                        ],
                                       startPoint: .leading,
                                       endPoint:.trailing)
                        :
                            LinearGradient(colors: [
                                Color(hex: 0x111827)
                            ],
                                           startPoint: .leading,
                                           endPoint:.trailing)
                        
                    )
                    .onTapGesture {
                        selection = .home
                    }
                
                Text("Home")
                    .font(.system(size: 13,weight: .semibold))
                    .foregroundStyle(Color(hex: 0x111827))
            }
            .frame(maxHeight:.infinity,alignment: .bottom)
            .padding(.bottom,15)
        
            Spacer()
            
            VStack(spacing: 7){
                
                Image("templates_icon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundStyle(
                        selection == .templates ?
                        LinearGradient(colors: [
                            Color(hex: 0x00FFF0),
                            Color(hex: 0x7B2FF7),
                            Color(hex: 0xFF3CAC)
                        ],
                                       startPoint: .leading,
                                       endPoint:.trailing)
                        :
                            LinearGradient(colors: [
                                Color(hex: 0x111827)
                            ],
                                           startPoint: .leading,
                                           endPoint:.trailing)
                        
                    )
                    .onTapGesture {
                        selection = .templates
                    }
                
                Text("Templates")
                    .font(.system(size: 13,weight: .semibold))
                    .foregroundStyle(Color(hex: 0x111827))
            }
            .frame(maxHeight:.infinity,alignment: .bottom)
            .padding(.bottom,15)
            
            Image("create_button")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .padding(.bottom,30)
                .onTapGesture {
                    router.push(Route.Create)
                }
            
            VStack(spacing: 7){
                
                Image("history_icon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundStyle(
                        selection == .history ?
                        LinearGradient(colors: [
                            Color(hex: 0x00FFF0),
                            Color(hex: 0x7B2FF7),
                            Color(hex: 0xFF3CAC)
                        ],
                                       startPoint: .leading,
                                       endPoint:.trailing)
                        :
                            LinearGradient(colors: [
                                Color(hex: 0x111827)
                            ],
                                           startPoint: .leading,
                                           endPoint:.trailing)
                        
                    )
                    .onTapGesture {
                        selection = .history
                    }
                
                Text("History")
                    .font(.system(size: 13,weight: .semibold))
                    .foregroundStyle(Color(hex: 0x111827))
            }
            .frame(maxHeight:.infinity,alignment: .bottom)
            .padding(.bottom,15)
            
            Spacer()
            
            VStack(spacing: 7){
                
                Image("settings_icon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundStyle(
                        selection == .settings ?
                        LinearGradient(colors: [
                            Color(hex: 0x00FFF0),
                            Color(hex: 0x7B2FF7),
                            Color(hex: 0xFF3CAC)
                        ],
                                       startPoint: .leading,
                                       endPoint:.trailing)
                        :
                            LinearGradient(colors: [
                                Color(hex: 0x111827)
                            ],
                                           startPoint: .leading,
                                           endPoint:.trailing)
                        
                    )
                    .onTapGesture {
                        selection = .settings
                    }
                
                Text("Settings")
                    .font(.system(size: 13,weight: .semibold))
                    .foregroundStyle(Color(hex: 0x111827))
            }
            .frame(maxHeight:.infinity,alignment: .bottom)
            .padding(.bottom,15)
            
            Spacer()
                
            
        }
        .frame(maxWidth:.infinity)
        .frame(height: 100)
        .background{
            Image("bottom_rect")
                .resizable()
                .scaledToFill()
        }
    }
}

#Preview {
    MainScreen()
}
