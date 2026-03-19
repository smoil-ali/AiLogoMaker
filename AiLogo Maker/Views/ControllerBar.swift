//
//  ControllerBar.swift
//  InvitationMaker
//
//  Created by Apple on 22/11/2025.
//

import SwiftUI

enum Tab{
    case AddText
    case AddImage
    case AddEffect
    case AddSticker
    case AddImport
    case GifMode
}

enum FooterAnim{
    case BounceIn
    case FadeIn
    case ZoomIn
}

enum TextProperty{
    case InputText
    case AdjustText
    case TextAlign
    case TextColor
}

struct ControllerBar: View {
    
    @Binding var selected: EditableLayer?
    @Binding var selectedTab: Tab?
    let beginScaling: () -> Void
    let endScaling: () -> Void
    let beginRotation: () -> Void
    let endRotation: () -> Void
    let onTextChanges: () -> Void
    let onNudge: (CGFloat,CGFloat) -> Void
    let onBounceIn: () -> Void
    let onFadeIn: () -> Void
    let onZoomIn: () -> Void
    let onDelete: (EditableLayer) -> Void
    let onChangeText: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        
        ZStack{
            
            
            switch selectedTab{
            case .AddText:
                TextHandler(selected: $selected,
                            beginScaling: beginScaling,
                            endScaling: endScaling,
                            beginRotation: beginRotation,
                            endRotation: endRotation,
                            onTextChanges: onTextChanges,
                            onNudge: onNudge,onDelete: {
                    if let l = selected{
                        onDelete(l)
                    }
                },onChangeText: onChangeText,
                  onCancel: onCancel
                )
                .frame(maxHeight: .infinity,alignment: .bottom)
            case .AddImage:
                ImageHandler(selected: $selected,
                             beginScaling: beginScaling,
                             endScaling: endScaling,
                             beginRotation: beginRotation,
                             endRotation: endRotation,
                             onNudge: onNudge,onDelete:{
                    if let l = selected{
                        onDelete(l)
                    }
                },onCancel: onCancel)
                .frame(maxHeight: .infinity,alignment: .bottom)
            case .AddEffect:
                EmptyView()
            case .AddSticker:
                EmptyView()
            case .AddImport:
                EmptyView()
            case .GifMode:
                FooterAnimation(selectedTab: .BounceIn, onSelectTab: { tab in
                    switch tab{
                    case .BounceIn:
                        onBounceIn()
                    case.FadeIn:
                        onFadeIn()
                    case.ZoomIn:
                        onZoomIn()
                    }
                })
                .frame(maxHeight: .infinity,alignment: .bottom)
            default:
                EmptyView()
            }
  
        }
        .frame(height: 220)
    
       

     
      
    }
}



struct TextHandler: View {
    
 
    @Binding var selected: EditableLayer?
    let beginScaling: () -> Void
    let endScaling: () -> Void
    let beginRotation: () -> Void
    let endRotation: () -> Void
    let onTextChanges: () -> Void
    var onNudge: (CGFloat,CGFloat) -> Void
    var onDelete: () -> Void

 
    @State var selectedTab: TextProperty = TextProperty.InputText
    
    let onChangeText: () -> Void
    var onCancel: () -> Void
    
    
    init(selected: Binding<EditableLayer?> = .constant(nil),
         beginScaling: @escaping () -> Void,
         endScaling: @escaping () -> Void,
         beginRotation: @escaping () -> Void,
         endRotation: @escaping () -> Void,
         onTextChanges: @escaping () -> Void,
         onNudge: @escaping (CGFloat, CGFloat) -> Void,
         onDelete: @escaping () -> Void,
         onChangeText: @escaping () -> Void,
         onCancel: @escaping () -> Void
         
    ) {
        
        self._selected = selected
        self.onNudge = onNudge
        self.onDelete = onDelete
        self.beginScaling = beginScaling
        self.endScaling = endScaling
        self.beginRotation = beginRotation
        self.endRotation = endRotation
        self.onTextChanges = onTextChanges
        self.onChangeText = onChangeText
        self.onCancel = onCancel
        self.selectedTab = selectedTab
  
    
     


    }
    
    var body: some View {
        VStack{
            
            HStack{
                
                VStack{
                    
                    Image("edit_text")
                        .scaledToFit()
                }
                .padding(.horizontal,7)
                .frame(maxHeight: .infinity)
                .frame(width: 70)
                .background( selectedTab == .InputText ? Color.yellow : Color.clear)
                .onTapGesture {
                    selectedTab = .InputText
                }
                
                VStack{
                    
                    Image("scaling_text")
                        .scaledToFit()
           
                }
                .padding(.horizontal,7)
                .frame(maxHeight: .infinity)
                .frame(width: 90)
                .background( selectedTab == .AdjustText ? Color.yellow : Color.clear)
                .onTapGesture {
                    selectedTab = .AdjustText
                }
             
                
                VStack{
                    
                    Image("align_text")
                        .scaledToFit()
          
                }
                .padding(.horizontal,7)
                .frame(maxHeight: .infinity)
                .frame(width: 70)
                .background( selectedTab == .TextAlign ? Color.yellow : Color.clear)
                .onTapGesture {
                    selectedTab = .TextAlign
                }
              
                
                VStack{
                    
                    Image("color_text")
                        .scaledToFit()
      
                }
                .padding(.horizontal)
                .frame(maxHeight: .infinity)
                .frame(width: 70)
                .background( selectedTab == .TextColor ? Color.yellow : Color.clear)
                .onTapGesture {
                    selectedTab = .TextColor
                }
                
                VStack{
                    
                    Text("Cancel")
                        .foregroundStyle(.white)
                        .font(.caption)
      
                }
     
                .frame(maxHeight: .infinity)
                .frame(width: 70)
                .background(Color.clear)
                .onTapGesture {
                    onCancel()
                }
              
                
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(cgColor: CGColor(red: 94.0/255, green: 47.0/255, blue: 119.0/255, alpha: 1.0)))
            
            
            Divider()
                .background(.white)
            
            Spacer()
            
   
            
            switch selectedTab {
            case .InputText:
                
                InputTextContainer(onChangeText: onChangeText)
                   

            case .AdjustText:
                TextAdjuster(
                    selected: $selected,
                    beginScaling: beginScaling,
                    endScaling: endScaling,
                    beginRotation: beginRotation,
                    endRotation: endRotation
                ){ x,y in
                    onNudge(x,y)
                }
            case .TextAlign:
                TextAlignmentAdjust(
                    selected: $selected,
                    leadingAction: {
                        if var s = selected,
                           case .text(var textProperty) = s.kind
                        {
                            // mutate the local copy
                            textProperty.hAlign = .left
                            s.kind = .text(textProperty)

                            // write the modified copy back to the Binding -> UI updates
                            selected = s
                        }
                    }, centreAction: {
                        if var s = selected,
                           case .text(var textProperty) = s.kind
                        {
                            // mutate the local copy
                            textProperty.hAlign = .center
                            s.kind = .text(textProperty)

                            // write the modified copy back to the Binding -> UI updates
                            selected = s
                        }
                    }, trailingAction: {
                        
                        if var s = selected,
                           case .text(var textProperty) = s.kind
                        {
                            // mutate the local copy
                            textProperty.hAlign = .right
                            s.kind = .text(textProperty)

                            // write the modified copy back to the Binding -> UI updates
                            selected = s
                        }
                        
                        
                    }, onDelete: {
                        onDelete()
                    }
                )
            case .TextColor:
                TextColorPicker{ color in
                    
                    
                    if var s = selected,
                       case .text(var textProperty) = s.kind
                    {
                        // mutate the local copy
                        if let rgb = color.toRGB(){
                            textProperty.color = ColorValue(r: rgb.red, g: rgb.green, b: rgb.blue, a: rgb.alpha)
                            s.kind = .text(textProperty)
                        }

                        // write the modified copy back to the Binding -> UI updates
                        selected = s
                        
                        onTextChanges()
                    }
                    
                }
            }
            
            
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 200)
        .background(Color(cgColor: CGColor(red: 94.0/255, green: 47.0/255, blue: 119.0/255, alpha: 1.0)))
    }
}

struct ImageHandler: View {
    
    @Binding var selected: EditableLayer?
    let beginScaling: () -> Void
    let endScaling: () -> Void
    let beginRotation: () -> Void
    let endRotation: () -> Void
    let onNudge: (CGFloat,CGFloat) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20){
            
            
            TextAdjuster(selected: $selected,
                         beginScaling: beginScaling,
                         endScaling: endScaling,
                         beginRotation: beginRotation,
                         endRotation: endRotation,
                         nudge: onNudge
            )
            
            
       
            
            Button(action: {
                onDelete()
            }, label: {
                
                Text("Delete Item")
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200, height: 40)
                    .background(.blue)
                    .cornerRadius(25)
                
            })
            
            
            
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 200,alignment: .bottom)
        .background(Color(cgColor: CGColor(red: 94.0/255, green: 47.0/255, blue: 119.0/255, alpha: 1.0)))
        .overlay{
            ZStack{
                
                Text("Cancel")
                    .foregroundStyle(.white)
                    .font(.caption)
                    .padding()
                    .onTapGesture {
                        onCancel()
                    }
            }
            .frame(maxWidth:.infinity,maxHeight: .infinity,alignment: .topTrailing)
        }
    }
}



struct InputTextContainer: View {
    
  

    
    let onChangeText: () -> Void
    
    
    
    var body: some View {
        
        ZStack{
            
            Button(action: {
                onChangeText()
            }, label: {
                
                Text("Change Text")
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200, height: 40)
                    .background(Color.blue)
                    .cornerRadius(25)
                
            })
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .center)
        
    
    }
}

struct TextAdjuster: View {
    
   
    @Binding var selected: EditableLayer?
    let beginScaling: () -> Void
    let endScaling: () -> Void
    let beginRotation: () -> Void
    let endRotation: () -> Void
    let nudge: (CGFloat, CGFloat) -> Void
    let step: CGFloat = 5
    
    var body: some View {
        HStack{
            
            VStack(spacing: 8) {
                
                
                RepeatButton(action: {nudge(0, -step)}, label: {
                    Image(systemName: "arrow.up")
                        .foregroundStyle(.white)
                        .fontWeight(.bold)
                })
             
                HStack(spacing: 24) {
                    RepeatButton(action: {nudge(-step, 0)}, label:{
                        Image(systemName: "arrow.left")
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                    })
                           
                    RepeatButton(action: {nudge(step, 0) }, label: {
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                    })
                }
                RepeatButton(action: {nudge(0, step) }, label: {
                        Image(systemName: "arrow.down")
                        .foregroundStyle(.white)
                        .fontWeight(.bold)
                })
            }
            .padding(.leading)
            
      
            
            VStack{
                
                VStack(alignment: .leading,spacing: 0) {
                    HStack {
                        Text("Scale")
                            .foregroundStyle(.white)
                        Text(String(format: "%.2fx", selected?.scale ?? 1))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { selected?.scale ?? 1 },
                            set: { v in
                                guard var s = selected else { return }
                                beginScaling()
                                s.scale = max(0.25, min(4, v))
                                selected = s
                                endScaling()
                            }
                        ),
                        in: 0.25...4.0
                    )
                }
                
                VStack(alignment: .leading,spacing: 0) {
                    HStack {
                        Text("Rotation")
                            .foregroundStyle(.white)
                        Text("\(Int(selected?.rotation ?? 0))°")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { selected?.rotation ?? 0 },
                            set: { v in
                                guard var s = selected else { return }
                                beginRotation()
                                s.rotation = v
                                selected = s
                                endRotation()
                            }
                        ),
                        in: -180...180
                    )
                }
            }
            .padding(.horizontal)
            
       
            
            
            
            
        }
        .padding(.horizontal,20)
        .frame(maxWidth: .infinity,alignment: .center)
    }
}

struct TextAlignmentAdjust: View {
    
    @Binding var selected: EditableLayer?
    let leadingAction: () -> Void
    let centreAction: () -> Void
    let trailingAction: () -> Void
    let onDelete: () -> Void
    var body: some View{
        
        VStack(spacing: 20){
            
            HStack(spacing: 50){
                
                
                Image("leading_align")
                    .onTapGesture {
                        leadingAction()
                    }
                Image("centre_align")
                    .onTapGesture {
                        centreAction()
                    }
                Image("trailing_align")
                    .onTapGesture {
                        trailingAction()
                    }
                
                
            }
            
            Button(action: {
                onDelete()
            }, label: {
                
                Text("Delete Item")
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200, height: 40)
                    .background(.blue)
                    .cornerRadius(25)
                
            })
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .center)
    }
}

struct TextColorPicker: View {
    
    let onDone: (Color) -> Void
    @State private var selectedColor: Color = .blue
    var body: some View {
        VStack(alignment: .center) {
                 ColorPicker("Choose your color", selection: $selectedColor)
                     .padding()
                     .foregroundStyle(.white)
                     
            
            
            Button(action: {
                onDone(selectedColor)
            }, label: {
                
                Text("Select Me")
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200, height: 40)
                    .background(selectedColor)
                    .cornerRadius(25)
                
            })
            
             }
        .padding(.horizontal)
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .center)
        
    }
}

struct Footer: View{
    
//    @State var selectedTab: Tab? = nil
    let onSelectTab: (Tab) -> Void
    
    var body: some View{
        HStack{
            
//            VStack{
//                
//                Image("footer_text")
//                    .scaledToFit()
//                
//                Text("Add Text")
//                    .foregroundStyle(Color.white)
//            }
//            .padding(.horizontal,7)
//            .frame(maxHeight: .infinity)
//            .frame(width: 100)
////            .background( selectedTab == .AddText ? Color.yellow : Color.clear)
//            .onTapGesture {
//                onSelectTab(Tab.AddText)
//            }
            
            VStack{
                
                Image("footer_effect")
                    .scaledToFit()
                
                Text("Effect")
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal,7)
            .frame(maxHeight: .infinity)
            .frame(width: 100)
//            .background( selectedTab == .AddEffect ? Color.yellow : Color.clear)
            .onTapGesture {
                onSelectTab(Tab.AddEffect)
            }
         
            
            VStack{
                
                Image("footer_regular")
                    .scaledToFit()
                
                Text("Stickers")
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal,7)
            .frame(maxHeight: .infinity)
            .frame(width: 100)
//            .background( selectedTab == .AddSticker ? Color.yellow : Color.clear)
            .onTapGesture {
                onSelectTab(Tab.AddSticker)
            }
          
            
            VStack{
                
                Image("footer_import")
                    .scaledToFit()
                
                Text("Import")
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal,7)
            .frame(maxHeight: .infinity)
            .frame(width: 100)
//            .background( selectedTab == .AddImage ? Color.yellow : Color.clear)
            .onTapGesture {
                onSelectTab(Tab.AddImage)
            }
          
            
            
            
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(Color(cgColor: CGColor(red: 94.0/255, green: 47.0/255, blue: 119.0/255, alpha: 1.0)))
        
    }
}

struct FooterAnimation: View{
    
    @State var selectedTab: FooterAnim? = nil
    let onSelectTab: (FooterAnim) -> Void
    
    var body: some View{
        HStack{
            
            
            VStack{
                
                Text("Bounce In")
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal,7)
            .frame(maxHeight: .infinity)
            .frame(width: 100)
//            .background( selectedTab == .AddEffect ? Color.yellow : Color.clear)
            .onTapGesture {
                onSelectTab(FooterAnim.BounceIn)
            }
         
            
            VStack{
                
                
                Text("Zoom In")
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal,7)
            .frame(maxHeight: .infinity)
            .frame(width: 100)
//            .background( selectedTab == .AddSticker ? Color.yellow : Color.clear)
            .onTapGesture {
                onSelectTab(FooterAnim.ZoomIn)
            }
          
            
            VStack{
                
                Text("Fade In")
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal,7)
            .frame(maxHeight: .infinity)
            .frame(width: 100)
//            .background( selectedTab == .AddImage ? Color.yellow : Color.clear)
            .onTapGesture {
                onSelectTab(FooterAnim.FadeIn)
            }

        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(Color(cgColor: CGColor(red: 94.0/255, green: 47.0/255, blue: 119.0/255, alpha: 1.0)))
        
    }
}


#Preview {
    ControllerBar(selected: .constant(nil), selectedTab: .constant(nil),
                  beginScaling: {},
                  endScaling: {},
                  beginRotation: {},
                  endRotation: {},
                  onTextChanges: {}
                  ,onNudge: {_,_ in},
                  onBounceIn: {},
                  onFadeIn: {},
                  onZoomIn: {},
                  onDelete: {_ in},
                  onChangeText: {},
                  onCancel: {}
    )
}
