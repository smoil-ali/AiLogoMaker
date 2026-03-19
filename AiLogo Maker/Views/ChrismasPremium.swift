//
//  PremiumScreen.swift
//  Ai Image Art
//
//  Created by Apple on 04/10/2025.
//

import SwiftUI

struct ChrismasPremium: View {
    // Inject your purchasing actions
    
   
    @AppStorage("pro") private var isPro = false
    var onPurchase: (Plan) -> Void = { _ in }
    var onRestore: () -> Void = {}
    var onContinueFree: () -> Void = {}
    var termsURL: URL = URL(string: "https://trending-apple-google-apps.blogspot.com/2025/09/privacy-policy.html")!
    var privacyURL: URL = URL(string: "https://trending-apple-google-apps.blogspot.com/2025/09/terms-of-use.html")!

    @EnvironmentObject var vm: PaywallVM
    @EnvironmentObject var route: NavigationRouter

    
   

    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    
    @State private var trial: Bool = true


    // Plans
    @State private var selected: Int = 2


    var body: some View {
        

        ZStack {
   
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
              
              
                        
                    

                    ZStack{
                        
                        
                        
                        VStack(spacing: 16) {
                            // Title
                            
                            Spacer(minLength: 230)
                            
                            
                            HeaderTitle()
                            
                            Text("Unlock all features with Pro")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, 20)
                                .padding(.top, 4)

                            // Features (two columns)
                            FeatureGrid()
                                .padding(.horizontal, 20)
                            
                            
                            VStack(spacing: 14) {
                                
                        
                                if !vm.manager.plans.isEmpty {
                                    PlanRow(
                                        plan: vm.manager.plans[0],
                                        isSelected: (selected == 1) ? true : false
                                    ) { id in
                                        selected = 1
                                        if trial{
                                            trial = false
                                        }
                                    }
                                    
                                    if trial{
                                        PlanRow(
                                            plan: vm.manager.plans[2],
                                            isSelected: (selected == 2) ? true : false
                                        ) { id in
                                            selected = 2
                                         
                                        }
                                    }else{
                                        PlanRow(
                                            plan: vm.manager.plans[1],
                                            isSelected: (selected == 2) ? true : false
                                        ) { id in
                                            selected = 2
                                        }
                                    }
                                }
                                
                                
                               
                                
                    
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                            
                            Button(action: {
                                Task{
                              
                        
                                    
                                    let result: Bool = if selected == 1{
                                        await vm.buyMonthly()
                                    }else if selected == 2 && !trial{
                                        await vm.buyWeekly()
                                    }else{
                                        await vm.buyWeeklyTrial()
                                    }
                                    
                                    print("purchase is \(result)")
                                    if result{
                                        isPro = true
                                        dismiss()
                                    }
                                    
                                }
                            }) {
                                
                                HStack{
                                    
                                    Text(trial ? "Start Your Free Trial" :"Get Access Now")
                                        .font(.headline.bold())
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


                            // Auto-renew note
                            Text("Auto renewable. Cancel anytime")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: 0x505050))
                                .padding(.top, 6)

                            // Footer links
                            FooterLinks(
                                onContinueFree: {
                                    dismiss()
                                },
                                termsURL: termsURL,
                                privacyURL: privacyURL
                            )
                            .padding(.bottom, 24)
                        }
                    }
              

                }
            }
        }
        .frame(maxWidth:.infinity,maxHeight: .infinity)
        .background(content: {
            Image("pro_screen_bg")
                .resizable()
                .scaledToFill()
        })
      
        
    }
}

private struct HeaderTitle: View {
    var body: some View {
        HStack{
            
            
            
            
            Text("Ai Logo Generator")
                .foregroundStyle(.black)
                .font(.system(size: 24))
                .fontWeight(.bold)
          
            
            Button(action: {
                
            }) {
                
                HStack{
                    
                    Image("crown_icon")
                        .resizable()
                        .frame(width: 15,height: 15)
                        .scaledToFit()
                    
                    
                    Text("Get Pro")
                        .fontWeight(.regular)
                        .padding(.vertical,1)
                        .foregroundStyle(.white)
                    
                   
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
        .frame(maxWidth:.infinity,alignment: .center)

    }
}

private struct FeatureGrid: View {
    private let left = [
        "Use Premium Styles",
        "No Watermark",
        "Unlimited Artwork Creation",
        "Unlock 20+ Styles",
        "No Ads"
    ]

    var body: some View {
        HStack(alignment: .top,spacing: 24) {
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                ForEach(left, id: \.self) { row(text: $0) }
            }
            Spacer()
        }
        
    }
    @ViewBuilder private func row(text: String) -> some View {
        HStack(spacing: 10) {
            Circle().fill(.black).frame(width: 6, height: 6)
            Text(text).foregroundStyle(.black).font(.headline)
        }
        
    }
}



private struct PlanRow: View {
    let plan: Plan
    let isSelected: Bool
    var onTap: (Int) -> Void

    var body: some View {
        Button(action: {onTap(plan.id)}) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.title3.bold())
                            .foregroundStyle(.black)
                    }
                }
                Spacer()
                Text(plan.priceText)
                    .font(.title3.bold())
                    .foregroundStyle(.black)
                Radio(isOn: isSelected)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background{
                if isSelected{
                    Capsule()
                        .strokeBorder(
                            LinearGradient(colors: [
                                Color(hex: 0x00FFF0),
                                Color(hex: 0x7B2FF7),
                                Color(hex: 0xFF3CAC),
                            ], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                }else{
                    
                    Capsule()
                        .strokeBorder(Color(hex: 0x505050), lineWidth: 1)
           
                }
            }
            .background(.white, in: .capsule)
            .padding(.horizontal)
            
            .overlay{
                
                
                if let tag = plan.tagText {
                    SaveTag(text: tag)
                        .offset(y: -35)
                        .frame(maxWidth: .infinity,alignment: .trailing)
                        .padding(.trailing,50)
                }
                
                RoundedRectangle(cornerRadius: 28)
                    .stroke(isSelected ? Color.white.opacity(0.38) : Color.white.opacity(0.15), lineWidth: 1)
                
            }

        }
        .buttonStyle(.plain)
    }
}

private struct Radio: View {
    var isOn: Bool
    var body: some View {
        ZStack {
            
            Circle().stroke(
                LinearGradient(colors: [Color(hex: 0xF107A3),
                                        Color(hex: 0x7B2FF7)
                                       ],
                               startPoint: .leading, endPoint: .trailing)
                , lineWidth: 2).frame(width: 30, height: 30)
            if isOn {
                Circle().fill(
                    LinearGradient(colors: [Color(hex: 0xF107A3),
                                            Color(hex: 0x7B2FF7)
                                           ],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: 16, height: 16)
            }
        }
    }
}

private struct SaveTag: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                LinearGradient(colors: [Color(hex: 0xF107A3),
                                        Color(hex: 0x7B2FF7)
                                       ],
                               startPoint: .leading, endPoint: .trailing),
                in: Capsule()
            )
    }
}

private struct FooterLinks: View {
    var onContinueFree: () -> Void
    var termsURL: URL
    var privacyURL: URL
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 20) {
                
                Button("Privacy Policy") { openURL(privacyURL) }
                    .font(.system(size: 12,weight: .semibold))
                    .foregroundStyle(Color(hex: 0x111827))
           
                Text("|")
                    .foregroundStyle(Color(hex: 0x111827))
                
                Button("Term of Use") { openURL(termsURL) }
                    .font(.system(size: 12,weight: .semibold))
                    .foregroundStyle(Color(hex: 0x111827))
                Text("|")
                    .foregroundStyle(Color(hex: 0x111827))
            
                Button("Continue For Free") { onContinueFree() }
                    .font(.system(size: 12,weight: .semibold))
                    .foregroundStyle(Color(hex: 0x111827))
            }
            .multilineTextAlignment(.center)

            Text("By continuing you agree to our Terms and Privacy policies\nSubscription will auto-renew. Cancel anytime.")
                .font(.footnote)
                .foregroundStyle(Color(hex: 0x505050))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 6)
    }
}

// MARK: - Collage header (drop in your assets)



/// A single-image header that uses the image's full height (scaled to screen width).
private struct CollageHeader: View {
    var imageName: String = "premium_bg"   // your asset name

    var body: some View {
        GeometryReader { geo in
            if let ui = UIImage(named: imageName) {
                let ratio = ui.size.height / ui.size.width        // H / W
                let width  = geo.size.width
                let height = width * ratio

                ZStack(alignment: .bottom) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()                            // ← no cropping
                        .frame(width: width)                      // width drives height
                        .clipped()

                    // readability fade over the full image area
                    LinearGradient(colors: [
                        Color(hex: 0x201838, alpha: 0),
                        Color(hex: 0x201838,alpha:0.86),
                        Color(hex:0x201838,alpha: 1),
                        Color(hex:0x201838,alpha: 1),
                        Color(hex:0x201838,alpha: 1),
                        Color(hex:0x201838,alpha: 1)
                                           ],
                                   startPoint: .center, endPoint: .bottom)
                        .frame(width: width, height: height)
                        
                     
                }
                .frame(width: width, height: height)
            } else {
                // Fallback if asset missing
                Color.black.frame(height: 360)
            }
        }
        .ignoresSafeArea(.all)
        .frame(maxWidth: .infinity) // height is provided by inner content
      
    }
}






#Preview {
    ChrismasPremium()
        .environmentObject(PaywallVM())
      
}
