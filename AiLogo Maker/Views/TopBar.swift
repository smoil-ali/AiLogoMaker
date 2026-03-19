//
//  TopBar.swift
//  InvitationMaker
//
//  Created by Apple on 24/11/2025.
//

import SwiftUI

struct TopBar: View {
    
    let onBack: () -> Void
    let onLayer: () -> Void
    let onUndo: () -> Void
    let onReset: () -> Void
    let onRedo: () -> Void
    let onGif: () -> Void
    let onSave : () -> Void
    var body: some View {
        
        
        HStack{
            
            Image(systemName: "arrow.left")
                .resizable()
                .scaledToFit()
                .padding(8)
                .foregroundStyle(.white)
                .frame(width: 30,height: 30, alignment: .center)
                .padding(8)
                .background(Color(cgColor: CGColor(red: 94.0/255, green: 47.0/255, blue: 119.0/255, alpha: 1.0)))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    onBack()
                }
            
            Image("layers_icon")
                .resizable()
                .scaledToFit()
                .padding(8)
                .frame(width: 30,height: 30, alignment: .center)
                .padding(8)
                .background(Color(cgColor: CGColor(red: 94.0/255, green: 47.0/255, blue: 119.0/255, alpha: 1.0)))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    onLayer()
                }
            
            Image("undo_icon")
                .resizable()
                .scaledToFit()
                .padding(8)
                .frame(width: 30,height: 30, alignment: .center)
                .padding(8)
                .background(Color(cgColor: CGColor(red: 94.0/255, green: 47.0/255, blue: 119.0/255, alpha: 1.0)))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    onUndo()
                }
            
            Image("reset_icon")
                .resizable()
                .scaledToFit()
                .padding(8)
                .frame(width: 30,height: 30, alignment: .center)
                .padding(8)
                .background(Color(cgColor: CGColor(red: 94.0/255, green: 47.0/255, blue: 119.0/255, alpha: 1.0)))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    onReset()
                }
            
            Image("redo_icon")
                .resizable()
                .scaledToFit()
                .padding(8)
                .frame(width: 30,height: 30, alignment: .center)
                .padding(8)
                .background(Color(cgColor: CGColor(red: 94.0/255, green: 47.0/255, blue: 119.0/255, alpha: 1.0)))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    onRedo()
                }
            
            Image(systemName: "app.gift")
                .resizable()
                .scaledToFit()
                .padding(8)
                .foregroundStyle(.white)
                .tint(.white)
                .frame(width: 30,height: 30, alignment: .center)
                .padding(8)
                .background(Color(cgColor: CGColor(red: 94.0/255, green: 47.0/255, blue: 119.0/255, alpha: 1.0)))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    onGif()
                }
            Image(systemName: "square.and.arrow.down.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .tint(.white)
                .padding(8)
                .frame(width: 30,height: 30, alignment: .center)
                .padding(8)
                .background(Color(cgColor: CGColor(red: 94.0/255, green: 47.0/255, blue: 119.0/255, alpha: 1.0)))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    onSave()
                }
        }
        

        
        
           
    }
}

#Preview {
    TopBar(onBack:{},onLayer: {}, onUndo: {}, onReset: {}, onRedo: {},onGif: {}, onSave: {}
        
    )
}
