//
//  AiLogo_MakerApp.swift
//  AiLogo Maker
//
//  Created by Apple on 24/02/2026.
//

import SwiftUI
import FirebaseCore
import AppTrackingTransparency

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    
      FirebaseApp.configure()
      Task { await RemoteConfigManager.shared.fetchAndActivate() }
            RemoteConfigManager.shared.startRealtimeUpdates()
    return true
  }
}

@main
struct AiLogo_MakerApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var router = NavigationRouter()
    @StateObject var editorViewModel = EditorViewModel()
    @AppStorage("pro") private var isPro = false
    @StateObject var saveVm = SaveViewModel()
    @StateObject var fileVm = FileViewModel()
    @StateObject private var appOpenAdManager = AppOpenAdManager()
    @StateObject var vm = PaywallVM()

    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .environmentObject(editorViewModel)
                .environmentObject(saveVm)
                .environmentObject(fileVm)
                .environmentObject(vm)
                .task {
                    
                    await vm.manager.refreshProducts()
                    await vm.manager.refreshEntitlements()
                    isPro = vm.manager.isPro
                   
                    let rc = RemoteConfigManager.shared
                
                    
                    print("pro \(isPro)")
                    
                }
                .onAppear {
                    if !isPro{
                        appOpenAdManager.loadAd()
                    }
                    
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    
                    if !isPro{
                        
                        appOpenAdManager.showAdIfAvailable()
                    }
               
                    ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in })
    
                }
        }
    }
}
