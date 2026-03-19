//
//  NavigationRoute.swift
//  Goon Free
//
//  Created by Apple on 20/10/2025.
//

import Foundation
import SwiftUI

@MainActor
final class NavigationRouter: ObservableObject {
    @Published var path: [Route] = []

    // Convenience helpers
    func push(_ route: Route)        {
    
        path.append(route)
    }
    func pop()                        { _ = path.popLast() }
    func popToRoot()                  { path = [] }
    func replace(with routes: [Route]){ path = routes }
    
    func popAndPush(_ route: Route) {
        if !path.isEmpty { _ = path.popLast() }
        if path.last != route {
            path.append(route)
        }
    }
    
    func resetAndPush(_ route: Route) {
         path = [route]
     }
    
    func resetToHome() {
        // remove all items except first
        guard let first = path.first else {
            // nothing to keep
            path = []
            return
        }
        // keep only the first element
        path = [first]
    }
    
    func specialBack() {
        
        print("\(path.count)")
        if path.count == 0 {
            popAndPush(Route.Home)
        }else{
            pop()
        }
    }
}
