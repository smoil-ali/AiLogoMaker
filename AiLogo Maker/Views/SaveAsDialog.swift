//
//  SaveAsDialog.swift
//  InvitationMaker
//
//  Created by Apple on 07/01/2026.
//

import SwiftUI


struct SaveAsDialog: View {
    
    let actionAnimation: () -> Void
    let actionImage: () -> Void
    var body: some View {
        
        VStack{
            
            Text("Save as")
                .foregroundStyle(.black)
                .frame(maxWidth:.infinity,alignment: .leading)
            
            Button(action: {
                actionAnimation()
            }, label: {
                Text("Animation")
                    .foregroundStyle(.black)
                    .frame(maxWidth:.infinity)
                    .padding(.vertical,10)
                    .background(Color(hex: 0xD9D9D9))
                    .clipShape(.rect(cornerRadius: 16))
                    .padding()
               
            })
            
            Button(action: {
                actionImage()
            }, label: {
                Text("Image")
                    .foregroundStyle(.black)
                    .frame(maxWidth:.infinity)
                    .padding(.vertical,10)
                    .background(Color(hex: 0xD9D9D9))
                    .clipShape(.rect(cornerRadius: 16))
                    .padding()
               
            })
                
        }
        .padding()
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16, style: .continuous
            )
            .stroke(Color(.black), lineWidth: 1)
        )
  
    }
}

struct AnimationDialog: View {
    
    let actionGif: () -> Void
    let actionVideo: () -> Void
    let actionBounceIn: () -> Void
    let actionZoomIn: () -> Void
    let actionNext: (Int) -> Void
    @State private var formatSelected = 0
    @State private var animationSelected = -1
    var body: some View {
        VStack{
            
            Text("Format")
                .foregroundStyle(.black)
                .frame(maxWidth:.infinity,alignment: .leading)
            
            HStack{
                Button(action: {
                    formatSelected = 0
                    actionGif()
                }, label: {
                    Text("Gif")
                        .foregroundStyle(.black)
                        .frame(maxWidth:.infinity)
                        .padding(.vertical,10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: 0xD9D9D9))
                                .stroke( formatSelected == 0 ? .black : .clear, lineWidth: 1)
                        )
                        .clipShape(.rect(cornerRadius: 16))
                        .padding()
                   
                })
                
//                Button(action: {
//                    formatSelected = 1
//                    actionVideo()
//                }, label: {
//                    Text("Video")
//                        .foregroundStyle(.black)
//                        .frame(maxWidth:.infinity)
//                        .padding(.vertical,10)
//                        .background(
//                            RoundedRectangle(cornerRadius: 16)
//                                .fill(Color(hex: 0xD9D9D9))
//                                .stroke( formatSelected == 1 ? .black : .clear, lineWidth: 1)
//                        )
//                        .clipShape(.rect(cornerRadius: 16))
//                        .padding()
//                   
//                })
            }
            
            Text("Animations")
                .foregroundStyle(.black)
                .frame(maxWidth:.infinity,alignment: .leading)
            
            HStack{
                Button(action: {
                    animationSelected = 0
                    actionBounceIn()
                }, label: {
                    Text("Bounce In")
                        .foregroundStyle(.black)
                        .frame(maxWidth:.infinity)
                        .padding(.vertical,10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: 0xD9D9D9))
                                .stroke( animationSelected == 0 ? .black : .clear, lineWidth: 1)
                        )
                        .clipShape(.rect(cornerRadius: 16))
                        .padding()
                   
                })
                
                Button(action: {
                    animationSelected = 1
                    actionZoomIn()
                }, label: {
                    Text("Zoom In")
                        .foregroundStyle(.black)
                        .frame(maxWidth:.infinity)
                        .padding(.vertical,10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: 0xD9D9D9))
                                .stroke( animationSelected == 1 ? .black : .clear, lineWidth: 1)
                        )
                        .clipShape(.rect(cornerRadius: 16))
                        .padding()
                   
                })
            }
            
            Button(action: {
                actionNext(animationSelected)
            }, label: {
                Text("Save")
                    .foregroundStyle(.black)
                    .frame(maxWidth:.infinity)
                    .padding(.vertical,10)
                    .background(Color(hex: 0xD9D9D9))
                    .clipShape(.rect(cornerRadius: 16))
                    .padding()
               
            })
            
            
        }
        .padding()
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16, style: .continuous
            )
            .stroke(Color(.black), lineWidth: 1)
        )
    }
}


struct FormatDialog: View {
    
    let actionJPEG: () -> Void
    let actionPNG: () -> Void
    let actionPDF: () -> Void
    let actionSIMPLE: () -> Void
    let actionHD: () -> Void
    let actionDownload: (Int,Int) -> Void
    @State private var formatSelected = 0
    @State private var qualitySelected = 1
    var body: some View {
        VStack{
            
            Text("Format")
                .foregroundStyle(.black)
                .frame(maxWidth:.infinity,alignment: .leading)
            
            HStack{
                Button(action: {
                    formatSelected = 0
                    actionJPEG()
                }, label: {
                    Text("JPEG")
                        .foregroundStyle(.black)
                        .frame(maxWidth:.infinity)
                        .padding(.vertical,10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: 0xD9D9D9))
                                .stroke( formatSelected == 0 ? .black : .clear, lineWidth: 1)
                        )
                        .clipShape(.rect(cornerRadius: 16))
                        .padding()
                   
                })
                
                Button(action: {
                    formatSelected = 1
                    actionPNG()
                }, label: {
                    Text("PNG")
                        .foregroundStyle(.black)
                        .frame(maxWidth:.infinity)
                        .padding(.vertical,10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: 0xD9D9D9))
                                .stroke( formatSelected == 1 ? .black : .clear, lineWidth: 1)
                        )
                        .clipShape(.rect(cornerRadius: 16))
                        .padding()
                   
                })
                
                Button(action: {
                    formatSelected = 2
                    actionPDF()
                }, label: {
                    Text("PDF")
                        .foregroundStyle(.black)
                        .frame(maxWidth:.infinity)
                        .padding(.vertical,10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: 0xD9D9D9))
                                .stroke( formatSelected == 2 ? .black : .clear, lineWidth: 1)
                        )
                        .clipShape(.rect(cornerRadius: 16))
                        .padding()
                   
                })
            }
            
            Text("Quality")
                .foregroundStyle(.black)
                .frame(maxWidth:.infinity,alignment: .leading)
            
            HStack{
                Button(action: {
                    qualitySelected = 0
                    actionSIMPLE()
                }, label: {
                    Text("SIMPLE")
                        .foregroundStyle(.black)
                        .frame(maxWidth:.infinity)
                        .padding(.vertical,10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: 0xD9D9D9))
                                .stroke( qualitySelected == 0 ? .black : .clear, lineWidth: 1)
                        )
                        .clipShape(.rect(cornerRadius: 16))
                        .padding()
                   
                })
                
                Button(action: {
                    qualitySelected = 1
                    actionHD()
                }, label: {
                    Text("HD")
                        .foregroundStyle(.black)
                        .frame(maxWidth:.infinity)
                        .padding(.vertical,10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: 0xD9D9D9))
                                .stroke( qualitySelected == 1 ? .black : .clear, lineWidth: 1)
                        )
                        .clipShape(.rect(cornerRadius: 16))
                        .padding()
                   
                })
            }
            
            Button(action: {
                actionDownload(qualitySelected,formatSelected)
            }, label: {
                Text("Download")
                    .foregroundStyle(.black)
                    .frame(maxWidth:.infinity)
                    .padding(.vertical,10)
                    .background(Color(hex: 0xD9D9D9))
                    .clipShape(.rect(cornerRadius: 16))
                    .padding()
               
            })
        }
        .padding()
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16, style: .continuous
            )
            .stroke(Color(.black), lineWidth: 1)
        )
    }
}




#Preview {
    FormatDialog(actionJPEG: {}, actionPNG: {}, actionPDF: {}, actionSIMPLE: {}, actionHD: {}, actionDownload: {i,j in})

}
