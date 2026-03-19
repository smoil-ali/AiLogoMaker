//
//  Route.swift
//  Goon Free
//
//  Created by Apple on 08/10/2025.
//

import Foundation



enum Route: Hashable {
  
    case Main
    case Home
    case OnBoarding
    case SeeAll(String,String,Int)
    case TemplateScreen
    case Save(String)
    
    case Premium
    case Create
    case Shape
    case Icon
    case ChrismasPremium
    case AI
    case Generate(String)

}
