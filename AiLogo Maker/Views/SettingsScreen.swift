//
//  SettingsScreen.swift
//  AiLogo Maker
//
//  Created by Apple on 25/02/2026.
//

import SwiftUI

struct SettingsScreen: View {
    
    @EnvironmentObject var router: NavigationRouter
    var body: some View {
        VStack{
            
            Header(title: "Setting",onProAction: {
                router.push(Route.Premium)
            })
            
            Divider()
                .frame(maxWidth:.infinity)
                .frame(height: 1)
                .background(Color(hex: 0x11182766))
            
            ScrollView{
                
                AiContainerView(onAiAction: {
                    router.push(Route.Premium)
                })
                
                Spacer(minLength: 25)
                
                SettingBar(icon: "setting_screen_icon", title: "More Apps", action: {
                    
                })
                
                Spacer(minLength: 20)
                
                SettingBar(icon: "rate_us_icon", title: "Rate Us", action: {
                    
                })
                
                Spacer(minLength: 20)
                
                SettingBar(icon: "share_icon", title: "Share App", action: {
                    
                })
                
                Spacer(minLength: 20)
                
                SettingBar(icon: "privacy_icon", title: "Privacy Policy", action: {
                    
                })
                
                Spacer(minLength: 20)
                
                SettingBar(icon: "terms_icon", title: "Terms & Condition", action: {
                    
                })
                
                Spacer(minLength: 20)
                
                SettingBar(icon: "feedback_icon", title: "Feedback", action: {
                    
                })
                
                
            }
            
         
            
            
        }
        .frame(maxWidth:.infinity,maxHeight: .infinity,alignment: .top)
        .background(.white)
    }
}

private struct SettingBar: View {
    let icon: String
    let title: String
    let action: () -> Void
    var body: some View {
        HStack{
            
            HStack{
                
                Image(icon)
                    .scaledToFit()
                
                
                
                Text(title)
                    .foregroundStyle(Color(hex: 0x111827))
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
                    .padding(.leading,10)
            }
          
            
            
            Spacer()
            
            Image(systemName: "chevron.forward")
                .scaledToFit()
                .foregroundStyle(.black)
            
            
            
        }
        .padding(.horizontal,20)
        .padding(.vertical,15)
        .frame(maxWidth:.infinity)
        .background(Color(hex: 0xD7DDEC))
        .clipShape(.capsule)
        .frame(maxHeight:.infinity,alignment: .bottom)
        .padding(.horizontal)
    }
}

private struct AiContainerView: View {
    
    let onAiAction: () -> Void
    var body: some View {
        ZStack{
            
            Image("setting_banner_bg")
                .resizable()
                .padding(.horizontal)
                .frame(maxWidth:.infinity)
                .scaledToFill()
            
            Spacer()
            
            VStack{
                
                Text("Create")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth:.infinity,alignment: .leading)
                Text("Your Dream")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth:.infinity,alignment: .leading)
                Text("Logo")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth:.infinity,alignment: .leading)
                
                
                Button(action: {
                    onAiAction()
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
                    .frame(maxWidth:.infinity,alignment: .leading)
                    
                    

                }
                
            }
            .padding(.leading)
            .frame(maxWidth:.infinity,alignment: .leading)
            .padding(.leading)
            
          
          
            
            
        }
        
        .frame(height: 200)
        .frame(maxWidth:.infinity)
    }
}

#Preview {
    SettingsScreen()
}
