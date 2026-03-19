//
//  NewTemplateEditor.swift
//  InvitationMaker
//
//  Created by Apple on 11/12/2025.
//

import SwiftUI
import Photos
import CoreGraphics
import ImageIO
import MobileCoreServices
import UIKit


class EditorViewModel: ObservableObject {
    @Published var exportedImage: [UIImage] = []
    @Published var changes: Bool = false
}

struct NewTemplateEditor: View {
    
    public enum ScaleMode { case aspectFit, aspectFill, stretch }
 
    
    @AppStorage("pro") private var isPro = false
    let template: TemplateDocument
    let scaleMode: ScaleMode = .aspectFit
    @EnvironmentObject var vm: EditorViewModel
    @EnvironmentObject var route: NavigationRouter
    
    @Environment(\.dismiss) var dismiss
    @State private var layers: [EditableLayer] = []
    @State private var initialLayers: [EditableLayer] = []
    @State private var selectedID: UUID? = nil
    @State private var layerAnimations: [UUID: LayerAnimState] = [:]
    @State var controlKind: ControlKind? = nil
    @State var currentControll: ControlKind? = nil
    @State var selectedIdKind: Int = 0
    @State var showAddText = false
    @State var showEditText = false
    @State var editText: String = ""
    @State var addText: String = ""
    @State private var canvasSize: CGSize = .zero
    @State private var undoStack: [[EditableLayer]] = []
    @State private var redoStack: [[EditableLayer]] = []
    @State private var changeSessionActive: Bool = false
    @State private var changeSessionTimer: Timer? = nil
    private let changeSessionIdle: TimeInterval = 0.35
    @State private var showLayerPanel = false
    @State private var watermarkEnabled: Bool = true
    @State private var watermarkImageName: String = "watermark_icon" // asset name in bundle
    @State private var watermarkOpacity: CGFloat = 0.85
    @State private var watermarkSizeInCanvas: CGFloat = 80
    @State private var watermarkPaddingInCanvas: CGFloat = 12
    @State private var showSaveAlert = false
    @State private var saveResult = false
    @State private var animationError: Bool = false
    @State private var imageSave: Bool = false
    @State private var message = ""
    @State private var actionImport: Bool = false
    @EnvironmentObject var saveVm: SaveViewModel
    @EnvironmentObject var fileVm: FileViewModel
    @State private var isLoading: Bool = false
    @State private var showWaterAlert = false
    @State private var showReward = true
    @State private var adLoading = false
    @State private var showAlert = false
    @State private var adWaterMark = false
    let interstitialAd = InterstitialViewModel()
    @State private var currentTextAnimation: FooterAnim = .BounceIn
    @State private var showSaveAs = false
    @State private var showGifDialog = false
    @State private var showImageDialog = false
    
    

  

    
    var body: some View {
        
        
        VStack(spacing: 0){
            HStack{
                
                Image("back_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30,height: 30)
                    .onTapGesture {
                        
                        if showGifDialog{
                            showGifDialog = false
                            showSaveAs = true
                        }else if showImageDialog{
                            showImageDialog = false
                            showSaveAs = true
                        }else if showSaveAs{
                            showSaveAs = false
                        }else{
                            dismiss()
                        }
                    }
                
                Spacer()
                
                Text("Invitation Studio")
                    .foregroundStyle(Color(hex: 0x111827))
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Image("save_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30,height: 30)
                    .onTapGesture {
                        
                        showSaveAs = true
                        selectedID = nil
                        controlKind = nil
                        currentControll = nil
                        selectedIdKind = 0
                 
                        
//                        if isPro{
//                            let path = saveAsImage()
//                            route.push(Route.Save(path))
//                        }else{
//                            
//                            Task{
//                                adLoading = true
//                                await interstitialAd.loadAd()
//                                interstitialAd.showAd()
//                                adLoading = false
//                                isLoading = true
//                                let path = saveAsImage()
//                                route.push(Route.Save(path))
//                                isLoading = false
//                            }
//                        }
                    
                      
                        
                    }
                
            }
            .padding(.horizontal)
            
            
            GeometryReader { geo in
                let layout = LayoutMapper(
                    canvas: CGSize(width: template.canvas.width, height: template.canvas.height),
                    container: geo.size,
                    mode: map(scaleMode)
                )
                
                
                ZStack(alignment: .topLeading) {
                    // Draw layers in document order
                    ForEach(layers) { layer in
                        
                        
                        let rect = layout.mapRect(x: layer.x, y: layer.y, w: layer.width, h: layer.height)
                        
                        ZStack { // content + overlay share transforms
                            LayerRender(layer: layer, animState: layerAnimations[layer.id],scale: layout.scale)
                                .frame(width: rect.width, height: rect.height, alignment: .center)
                            SelectionOverlay(isSelected: layer.id == selectedID)
                                .frame(width: rect.width, height: rect.height)
                        }
                        .scaleEffect(layer.scale)
                        .rotationEffect(.degrees(layer.rotation), anchor: .center)
                        .position(x: rect.midX, y: rect.midY)
                        .contentShape(Rectangle()) // simplifies taps
                    }
                 
                }
                .background(Color.black)
                .overlay(
                    Group {
                        
                        if watermarkEnabled == true{
                            
                            let wm = loadWatermarkImage(named: watermarkImageName)
                            
                            ZStack{
                                
                                GIFWebView(gifName: "watermark_gif")
                                    .aspectRatio(contentMode: .fit)
                                    
                            }
                            .frame(width: watermarkSizeInCanvas * layout.scale,
                                   height: watermarkSizeInCanvas * layout.scale)
                            .padding(.bottom, watermarkPaddingInCanvas * layout.scale)
                            .padding(.trailing, watermarkPaddingInCanvas * layout.scale)
                            .onTapGesture{
                                showWaterAlert = true
                                
                            }
                        }
                    },
                    alignment: .bottomTrailing
                )
                .clipped()
                .frame(width: layout.contentSize.width, height: layout.contentSize.height)
                .position(x: geo.size.width/2, y: geo.size.height/2)
                .onAppear {
                
                    
                    
                    watermarkEnabled = !isPro && !adWaterMark
                    
             
                    if layers.isEmpty {
                        
                        
                        layers = EditableLayer.from(template: template)
                        
                        initialLayers = layers.map { $0 }
                        
                        canvasSize = geo.size
                      
                    }
                    
                    if vm.changes{
                        
                        if let image = vm.exportedImage.last{
                            
                            let x = (canvasSize.width) / 2
                            let y = (canvasSize.height) / 2
                            
                            
                            let layer = mapImageToLayer(input: image, width: image.size.width, height: image.size.height, x: x, y: y)
                            
                            
                            pushState(action: "add")
                            layers.append(layer)
                            vm.changes = false
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                                let offsetX = (geo.size.width  - layout.contentSize.width)  / 2
                                let offsetY = (geo.size.height - layout.contentSize.height) / 2
                                let p = CGPoint(x: value.location.x - offsetX,
                                                y: value.location.y - offsetY)

                                // 2) test from top to bottom
                                if let idx = layers.indices.reversed().first(where: {
                                    layerHitTest(layers[$0], tapInContainer: p, layout: layout)
                                }) {
                                    selectedID = layers[idx].id
                                    let l = layers.first(where: {$0.id == selectedID })
                                    controlKind = .controlls
                                    currentControll = .controlls
                                    showSaveAs = false
                                    showImageDialog = false
                                    
                         
                           
                                    switch l?.kind{
                                        
                                    case .image(_):
                                        selectedIdKind = 1
                                    case .text(_):
                                        selectedIdKind = 2

                                    default:
                                        selectedIdKind = 0
                                        
                                    }
                                    
                                } else {
//                                    selectedTab = nil
                                    selectedID = nil
                                    controlKind = nil
                                    currentControll = nil
                                    selectedIdKind = 0
                                }
                        }
                )
            }
            
            
            if showSaveAs{
                VStack{
                    SaveAsDialog(actionAnimation: {
                        showGifDialog = true
                        showSaveAs = false
                    }, actionImage: {
                        showImageDialog = true
                        showSaveAs = false
                    })
                }
                .frame(maxHeight:.infinity,alignment: .bottom)
            }else if showGifDialog{
                VStack{
                    AnimationDialog(actionGif: {},
                                    actionVideo: {},
                                    actionBounceIn: {
                        currentTextAnimation = .BounceIn
                        animateAll(.BounceIn)
                    },
                                    actionZoomIn: {
                        currentTextAnimation = .ZoomIn
                        animateAll(.ZoomIn)
                    },
                                    actionNext: { type in
                        
                        if type == -1{
                            animationError = true
                        }else{
                            saveAsGif(extType: ".gif")
                        }
                        
                        
                    }
                    )
                }
                .frame(maxHeight:.infinity,alignment: .bottom)
            }else if showImageDialog{
                VStack{
                    FormatDialog(actionJPEG: {
                        
                    },
                                 actionPNG: {},
                                 actionPDF: {},
                                 actionSIMPLE: {},
                                 actionHD: {},
                                 actionDownload:
                                    {quality,format in
                        
                        let image = saveAsImage()
                        
                        if format == 0{
                            saveAsJpeg(image: image)
                            imageSave = true
                        }else if format == 1{
                            saveAsPng(image: image)
                            imageSave = true
                        }else if format == 2{
                            saveAsPdf(image: image)
                            imageSave = true
                        }
                    })
                }
                .frame(maxHeight:.infinity,alignment: .bottom)
            } else{
                VStack{
                    
                    ToolsArea(
                        controllSelected: controlKind,
                        selectedIdKind: selectedIdKind,
                        isUndoEmpty: undoStack.isEmpty,
                        isRedoEmpty: redoStack.isEmpty,
                        actionUndo: {
                            if !undoStack.isEmpty{
                                undo()
                            }
                        },
                        actionRedo: {
                            if !redoStack.isEmpty{
                                redo()
                            }
                        },
                        actionLayers: {
                            showLayerPanel = true
                        },
                        actionBgColor: { color in
                            
                          
                        },
                        onDone: {
                            selectedID = nil
                            controlKind = nil
                            currentControll = nil
                        },
                        actionEditText: {
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return }
                            
                            if case .text(let textProperty) = layers[idx].kind {
                                // modify textProperty
                                
                                
                                editText = textProperty.text
                                showEditText = true
                   
                            }
                        },
                        actionCopy: {
                            
                            pushState(action: "copy")
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return }
                            
                            var layer = layers[idx].deepCopy()
                            
                            layer.x += 10
                            layer.y += 10
                            
                            layers.append(layer)
                            
                            selectedID = layer.id
                            
                            print("length \(layers.count)")
                           
                        },
                        actionDelete: {
                            
                            pushState(action: "delete")
                            if let index = layers.firstIndex(where: { $0.id == selectedID }) {
                                
                                layers.remove(at: index)
                                selectedID = nil
                                controlKind = nil
                                currentControll = nil
                            }
                  
                        },
                        actionUp: { dx,dy in
                      
                            
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return }
                            
                            beginAtomicChange(action: "translate")
                            layers[idx].x += dx
                            layers[idx].y += dy
                            scheduleEndAtomicChange()
                            
                        },
                        actionDown: { dx,dy in
                           
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return }
                            beginAtomicChange(action: "translate")
                            layers[idx].x += dx
                            layers[idx].y += dy
                            scheduleEndAtomicChange()
                     
                        },
                        actionLeft: {dx,dy in
                       
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return }
                            beginAtomicChange(action: "translate")
                            layers[idx].x += dx
                            layers[idx].y += dy
                            scheduleEndAtomicChange()
                         
                        },
                        actionRight: { dx,dy in
                       
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return }
                            
                            beginAtomicChange(action: "translate")
                            layers[idx].x += dx
                            layers[idx].y += dy
                            scheduleEndAtomicChange()
                       
                        },
                        actionFont: {font in
                            
                        },
                        actionBold: {
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return }
                            
                            if case .text(var textProperty) = layers[idx].kind {
                                // modify textProperty
                                
                                
                                textProperty.bold = !textProperty.bold
                                
                                pushState(action: "Bold")
                                layers[idx].kind = .text(textProperty)
                            }
                        },
                        actionUnderline: {
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return }
                            
                            if case .text(var textProperty) = layers[idx].kind {
                                // modify textProperty
                                
                                
                                textProperty.underline = !textProperty.underline
                                
                                pushState(action: "underline")
                                layers[idx].kind = .text(textProperty)
                            }
                        },
                        actionItalic: {
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return }
                            
                            if case .text(var textProperty) = layers[idx].kind {
                                // modify textProperty
                                
                                
                                textProperty.italic = !textProperty.italic
                                
                                pushState(action: "Italic")
                                layers[idx].kind = .text(textProperty)
                            }
                        },
                        actionCapital: {
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return }
                            
                            if case .text(var textProperty) = layers[idx].kind {
                                // modify textProperty
                                
                                
                                let rect = getTextWidth(
                                    input: textProperty.text,
                                    space: textProperty.space,
                                    font: textProperty.fontFamily,
                                    fontSize: textProperty.fontSize,
                                    isBold: textProperty.bold,
                                    isItalic: textProperty.italic
                                )
                                
                                
                                textProperty.capital = !textProperty.capital
                                pushState(action: "Capital")
                                layers[idx].width = rect.width
                                layers[idx].height = rect.height
                                layers[idx].kind = .text(textProperty)
                      
                            }
                        },
                        actionSmall: {
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return }
                            
                            if case .text(var textProperty) = layers[idx].kind {
                                // modify textProperty
                                
                                
                                textProperty.small = !textProperty.small
                                pushState(action: "Small")
                                layers[idx].kind = .text(textProperty)
                            }
                        },
                        actionColor: {color in
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return }
                            
                            if case .text(var textProperty) = layers[idx].kind {
                                // modify textProperty
             
                                if let rgb = color.toRGB(){
                                    
                                    beginAtomicChange(action: "color")
                                    textProperty.color = ColorValue(r: rgb.red, g: rgb.green, b: rgb.blue, a: rgb.alpha)
                                    layers[idx].kind = .text(textProperty)
                                    scheduleEndAtomicChange()
                                }
                            
                          
                              
                            }
                        },
                        actionShadowColor: {color in
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return}
                            
                            if case .text(var textProperty) = layers[idx].kind {
                                // modify textProperty
                                
                          
                                
                                beginAtomicChange(action: "shadow color")
                                textProperty.shadowColor = color
                                
                                layers[idx].kind = .text(textProperty)
                                scheduleEndAtomicChange()
                            }
                        },
                        getScale: {
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return 1}
                            
                            return layers[idx].scale
                        },
                        setScale: {v in
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return}
                            
                            beginAtomicChange(action: "scale")
                            layers[idx].scale = v
                            scheduleEndAtomicChange()
                        },
                        getRotation: {
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return 0}
                            
                            return layers[idx].rotation
                        },
                        setRotation: { v in
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return}
                            beginAtomicChange(action: "rotation")
                            layers[idx].rotation = v
                            scheduleEndAtomicChange()
                        },
                        getOpacity: {
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return 255}
                            
                            
                            
                            return layers[idx].opacity
                       
                            
                        },
                        setOpacity: { v in
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return}
                            
                            
                            layers[idx].opacity = v
                            
                        },
                        getSpace: {
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return 0}
                            
                            if case .text(let textProperty) = layers[idx].kind {
                                // modify textProperty
             
                                return textProperty.space
                            }
                            
                            return 100
                        },
                        setSpace: { v in
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return}
                            
                            if case .text(var textProperty) = layers[idx].kind {
                                // modify textProperty
                                
                                let rect = getTextWidth(
                                    input: textProperty.text,
                                    space: textProperty.space,
                                    font: textProperty.fontFamily,
                                    fontSize: textProperty.fontSize,
                                    isBold: textProperty.bold,
                                    isItalic: textProperty.italic
                                )
                                
                                
                                textProperty.space = v
                                beginAtomicChange(action: "space")
                                layers[idx].width = rect.width
                                layers[idx].height = rect.height
                                layers[idx].kind = .text(textProperty)
                                scheduleEndAtomicChange()
                            }
                        },
                        actionShadowDisplay: { show in
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return}
                            
                            if case .text(var textProperty) = layers[idx].kind {
                                // modify textProperty
             
                                textProperty.shadow = show
                                
                                pushState(action: "shadow_display")
                                layers[idx].kind = .text(textProperty)
                                
                            }
                        },
                        getX: {
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return 0}
                            
                            if case .text(let textProperty) = layers[idx].kind {
                                // modify textProperty
             
                                return textProperty.shadowX
                            }
                            
                            return 100
                        },
                        setX: { v in
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return}
                            
                            if case .text(var textProperty) = layers[idx].kind {
                                // modify textProperty
                                
                          
                                
                                
                                textProperty.shadowX = v
                                
                                beginAtomicChange(action: "shadowX")
                                layers[idx].kind = .text(textProperty)
                                scheduleEndAtomicChange()
                            }
                        },
                        getY: {
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return 0}
                            
                            if case .text(let textProperty) = layers[idx].kind {
                                // modify textProperty
             
                                return textProperty.shadowY
                            }
                            
                            return 100
                        },
                        setY: { v in
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return}
                            
                            if case .text(var textProperty) = layers[idx].kind {
                                // modify textProperty
                                
                          
                                
                                
                                textProperty.shadowY = v
                                
                                beginAtomicChange(action: "shadowY")
                                layers[idx].kind = .text(textProperty)
                                scheduleEndAtomicChange()
                            }
                        },
                        getBlur: {
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return 0}
                            
                            if case .text(let textProperty) = layers[idx].kind {
                                // modify textProperty
             
                                return textProperty.shadowBlur
                            }
                            
                            return 100
                        },
                        setBlur: { v in
                            guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return}
                            
                            if case .text(var textProperty) = layers[idx].kind {
                                // modify textProperty
                                
                          
                                
                                
                                textProperty.shadowBlur = v
                                beginAtomicChange(action: "blur")
                                layers[idx].kind = .text(textProperty)
                                scheduleEndAtomicChange()
                            }
                        }
                    )
                    .padding(.bottom)
                    
                    
                    
                    mFooter(
                        controlSelected: selectedID != nil,
                        selectedIdKind: selectedIdKind,
                        showFont: false,
                        showImport: true,
                        currentControll: $currentControll,
                        actionText: {showAddText = true},
                        actionIcon: {route.push(Route.Icon)},
                        actionShape: {route.push(Route.Shape)},
                        actionBackground: {},
                        actionImport: {actionImport = true},
                        actionControl: {controlKind = .controlls},
                        actionFont: {controlKind = .fonts},
                        actionSize: {controlKind = .size},
                        actionTextStyle: {controlKind = .style},
                        actionTextColor: {controlKind = .colors},
                        actionShadow: {controlKind = .shadow},
                        actionOpacity: {controlKind = .opacity},
                        actionRotate: {controlKind = .rotate},
                        actionSpacing: {controlKind = .spacing}
                        
                    )
                    
                }
                .frame(maxHeight:.infinity,alignment: .bottom)
            }
            
            
            
        }
        .frame(maxWidth:.infinity,maxHeight:.infinity)
        .background(.white)
        
        .sheet(isPresented: $showLayerPanel) {
            NewTemplatePanelView(layers: $layers, onMove: { from, to in
                // push a snapshot for undo BEFORE making the move
                pushState(action: "reorder")
                // perform the move
                layers.move(fromOffsets: from, toOffset: to)
                // clear redo stack because new action occurred
                redoStack.removeAll()
            })
            .presentationDetents([.medium, .large])
        }
        .onAppear{
            let rc = RemoteConfigManager.shared
            showReward = rc.bool("show_reward", default: false)
        }
        .onReceive(RemoteConfigManager.shared.objectWillChange) { _ in
            let rc = RemoteConfigManager.shared
            showReward = rc.bool("show_reward", default: false)
        }
        .loadingDialog(isPresented: $isLoading)
        .loadingDialog(isPresented: $adLoading,message: "Ad is Loading...")
        .imageSourceDialog(isPresented: $actionImport){ path in
            
            if let image = UIImage(contentsOfFile: path.path){
                
                let x = (canvasSize.width) / 2
                let y = (canvasSize.height) / 2
                
                
                let layer = mapImageToLayer(input: image, width: image.size.width, height: image.size.height, x: x, y: y)
                
                
                pushState(action: "add")
                layers.append(layer)
            }
            
         
  
        }
        .watermarkDialog(isPresented: $showWaterAlert,
                         showReward: showReward,
                         onPremium: {
            showWaterAlert = false
            route.push(Route.Premium)
        }, onAd: {
            
            Task{
                adLoading = true
                let reward = await showRewardAd()
                adLoading = false
                
                
                print("reward is \(reward)")
                if reward{
                    adWaterMark = true
                    print("water mark \(watermarkEnabled)")
                }else{
                    showAlert = true
                    message = "Ad not available"
                }
            }
            showWaterAlert = false
        }, onCancel: {
            showWaterAlert = false
        })
        .alert("Alert", isPresented: $showAlert, actions: {
            Button("Ok", action: {
                showAlert = false
            })
        }, message: {
            Text(message)
        })
        .alert("Alert", isPresented: $saveResult, actions: {
            Button("Ok", action: {
                saveResult = false
            })
        }, message: {
            Text(message)
        })
        .alert("Alert", isPresented: $animationError, actions: {
            Button("Ok", action: {
                animationError = false
            })
        }, message: {
            Text("Please select animation type")
        })
        .alert("Alert", isPresented: $imageSave, actions: {
            Button("Ok", action: {
                imageSave = false
            })
        }, message: {
            Text("Image has been saved")
        })
        .ignoresSafeArea(.keyboard)
        .overlay{
            if showEditText{
                VStack{
                    
                    HStack{
                        Image("back_icon")
                            .scaledToFit()
                            .onTapGesture {
                                showEditText = false
                            }
                        
                        Spacer()
                        
                        Image("add_text_done")
                            .scaledToFit()
                            .onTapGesture {
                                
                                
                                if !editText.isEmpty{
                                    guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return}
                                    
                                    if case .text(var textProperty) = layers[idx].kind {
                                        // modify textProperty
                                        
                                  
                                        let rect = getTextWidth(
                                            input: editText,
                                            space: textProperty.space,
                                            font: textProperty.fontFamily,
                                            fontSize: textProperty.fontSize,
                                            isBold: textProperty.bold,
                                            isItalic: textProperty.italic
                                        )
                                        textProperty.text = editText
                                        
                                        beginAtomicChange(action: "edit")
                                        layers[idx].kind = .text(textProperty)
                                        layers[idx].width = rect.width
                                        layers[idx].height = rect.height
                                        scheduleEndAtomicChange()
                                        showEditText = false
                                    }
                                }
                                
                       
                                
                            }
                    }
                    .padding(.horizontal)
                    
                    
                    TextField("",
                              text: $editText,
                              prompt:
                                Text("Edit Your Text")
                        .font(.largeTitle)
                        .foregroundColor(Color(hex: 0x111827))
                              
                    )
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .autocapitalization(.none)
                    .foregroundStyle(.black)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .frame(maxWidth:.infinity,maxHeight: .infinity,alignment: .center)
                    
                    
                    
                    
                }
                .frame(maxWidth:.infinity,maxHeight: .infinity,alignment: .top)
                .background(.white)
            }
            
            if showAddText{
                VStack{
                    
                    HStack{
                        Image("back_icon")
                            .scaledToFit()
                            .onTapGesture {
                                showAddText = false
                            }
                        
                        Spacer()
                        
                        Image("add_text_done")
                            .scaledToFit()
                            .onTapGesture {
                                
                                if !addText.isEmpty{
                                    
                                    let rect = getTextWidth(
                                        input: addText,
                                        space: 0,
                                        font: "Poppins-Regular",
                                        fontSize: 52,
                                        isBold: false,
                                        isItalic: false
                                    )
                                    
                                    let x = (canvasSize.width) / 2
                                    let y = (canvasSize.height) / 2
                                    
                                    
                                    let layer = mapTexttoLayer(input: addText,
                                                               rect: rect,
                                                               x: x, y: y,fontSize: 52)
                                    pushState(action: "add")
                                    layers.append(layer)
                                    
                                    showAddText = false
                                    addText = ""
                                }
                  
                                
                            }
                    }
                    .padding(.horizontal)
                    
                    
                    TextField("",
                              text: $addText,
                              prompt:
                                Text("Add Your Text")
                        .font(.largeTitle)
                        .foregroundColor(Color(hex: 0x111827))
                              
                    )
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .autocapitalization(.none)
                    .foregroundStyle(.black)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .frame(maxWidth:.infinity,maxHeight: .infinity,alignment: .center)
                    
                    
                    
                    
                }
                .frame(maxWidth:.infinity,maxHeight: .infinity,alignment: .top)
                .background(.white)
            }
            
        }
        
    }
    
    
    fileprivate func drawWatermark(in gc: CGContext,
                                   canvasSize: CGSize,
                                   watermark: UIImage,
                                   sizeInCanvas: CGFloat,
                                   paddingInCanvas: CGFloat,
                                   opacity: CGFloat) {
        gc.saveGState()
        // set alpha
        gc.setAlpha(opacity)

        // compute draw rect anchored at bottom-right
        let w = sizeInCanvas
        let h = sizeInCanvas
        let x = canvasSize.width - paddingInCanvas - w
        let y = canvasSize.height - paddingInCanvas - h

        // UIKit draws from top-left; our canvas origin is top-left as used previously,
        // so we can draw directly in rect (x,y,width,height)
        let drawRect = CGRect(x: x, y: y, width: w, height: h)
        watermark.draw(in: drawRect)

        gc.restoreGState()
    }
    
    private func showRewardAd() async -> Bool{
        
       
        if isPro || !showReward{
            return true
        }
        
        adLoading = true
        let adHandler = RewardedAdHandler()
        
        let ad = await adHandler.loadRewardedAd()
        
        adLoading = false
        
        if ad == nil{
            return false
        }
      
        let status = await adHandler.presentRewardedAd(ad:ad)
        
        if status{
            return true
        }
        
        
        return false

    }
    
    
    fileprivate func loadWatermarkImage(named name: String) -> UIImage? {
        #if os(iOS)
        return UIImage(named: name)
        #else
        return NSImage(named: name) // macOS branch if needed
        #endif
    }
    
    private func animateAll(_ type: FooterAnim) {
        guard !layers.isEmpty else { return }
        currentTextAnimation = type

        // Build list of text layer IDs in drawing order (you probably want top-to-bottom or bottom-to-top)
        // We'll animate top-to-bottom (last drawn -> first), change order if needed.
        let textLayerIndices = layers.enumerated().filter { _, l in
            if case .text = l.kind { return true } else { return false }
        }

        // If no text layers, nothing to do
        if textLayerIndices.isEmpty { return }

        // Prepare initial states depending on animation type
        layerAnimations.removeAll()

        // For deterministic ordering, get IDs in order we want to animate (here: top -> bottom)
        let idsToAnimate: [UUID] = textLayerIndices.map { $0.element.id }

        // Set initial state per type
        for id in idsToAnimate {
            switch type {
            case .FadeIn:
                layerAnimations[id] = LayerAnimState(opacity: 0.0, scale: 1.0, offset: .zero)
            case .BounceIn:
                layerAnimations[id] = LayerAnimState(opacity: 0.0, scale: 1.2, offset: CGSize(width: 0, height: -30))
            case .ZoomIn:
                layerAnimations[id] = LayerAnimState(opacity: 0.0, scale: 0.25, offset: .zero)
//            case .none:
//                layerAnimations[id] = LayerAnimState(opacity: 1.0, scale: 1.0, offset: .zero)
            }
        }

        // Staggered animation: animate each layer into final state with small delays
        // Final state: opacity 1, scale 1, offset .zero
        let baseDuration: Double = 0.45
        let stagger: Double = 0.08

        for (i, id) in idsToAnimate.enumerated() {
            let delay = Double(i) * stagger
            switch type {
            case .FadeIn:
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    withAnimation(.easeOut(duration: baseDuration)) {
                        layerAnimations[id]?.opacity = 1.0
                    }
                    // small bounce to avoid flatness (optional)
//                    withAnimation(.interpolatingSpring(stiffness: 180, damping: 18).delay(baseDuration)) {
//                        layerAnimations[id]?.scale = 1.0
//                        layerAnimations[id]?.offset = .zero
//                    }
                }

            case .BounceIn:
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    // fade + drop in with spring
                    withAnimation(.interpolatingSpring(stiffness: 120, damping: 12)) {
                        layerAnimations[id]?.opacity = 1.0
                        layerAnimations[id]?.scale = 0.95
                        layerAnimations[id]?.offset = .zero
                    }
                    // settle back to 1.0
                    try? await Task.sleep(nanoseconds: UInt64(0.12 * 1_000_000_000))
                    withAnimation(.easeOut(duration: 0.12)) {
                        layerAnimations[id]?.scale = 1.0
                    }
                }

            case .ZoomIn:
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    withAnimation(.easeOut(duration: baseDuration)) {
                        layerAnimations[id]?.opacity = 1.0
                        layerAnimations[id]?.scale = 1.0
                        layerAnimations[id]?.offset = .zero
                    }
                }

//            case .none:
//                // immediate reset
//                layerAnimations[id] = LayerAnimState(opacity: 1.0, scale: 1.0, offset: .zero)
            }
        }

        // Optionally clear the animation state after all done (so it doesn't persist)
        // We'll schedule a cleanup after the final animation finishes
        let totalDelay = Double(idsToAnimate.count) * stagger + baseDuration + 0.15
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(totalDelay * 1_000_000_000))
            currentTextAnimation = .BounceIn
            // leave final states applied for visual persistence; if you prefer to clear:
            // layerAnimations.removeAll()
        }
    }
    
    private func saveAsGif(
        extType:String
    ) {
        
        
        isLoading = true
        let duration: Double = 2.0
          let fps = 24
          let stagger: Double = 0.08
          // render + save
          renderAnimatedGIF(templateSize: CGSize(width: template.canvas.width, height: template.canvas.height),
                            layers: layers,
                            animation: currentTextAnimation,
                            duration: duration,
                            fps: fps,
                            stagger: stagger,
                            watermarkEnabled: true,
                            watermarkImageName: "watermark_icon",
                            watermarkSizeInCanvas: 80,
                            watermarkPaddingInCanvas: 12,
                            watermarkOpacity: 0.85,
                            extType: extType
                            ) { result in
              switch result {
              case .success(let fileURL):
                  // Optionally save to Photos
                  print("file url is \(fileURL.absoluteString)")
                  saveGIFToPhotos(fileURL: fileURL) { result in
                      switch result {
                      case .success():
                          print("GIF saved to Photos")
                          message = "GIF saved to Photos!"
                          isLoading = false
                          saveResult = true

                      case .failure(let err):
                          print("Failed to save GIF to Photos:", err)
                          message = "GIF Failed to save to Photos"
                          isLoading = false
                          saveResult = true

                      }
                  }
              case .failure(let err):
                  print("Failed to render GIF:", err)
                  message = "GIF Failed to save to Photos"
                  isLoading = false
                  saveResult = true

              }
          }
    }
    
    fileprivate func saveGIFToPhotos(fileURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        doSave()
                    } else {
                        completion(.failure(NSError(domain: "PhotoAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied."])))
                    }
                }
            }
        } else if status == .authorized || status == .limited {
            doSave()
        } else {
            completion(.failure(NSError(domain: "PhotoAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied."])))
        }

        func doSave() {
            PHPhotoLibrary.shared().performChanges({
                let req = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.uniformTypeIdentifier = kUTTypeGIF as String
                req.addResource(with: .photo, fileURL: fileURL, options: options)
            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(.success(()))
                    } else {
                        completion(.failure(error ?? NSError(domain: "SaveGIF", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unknown error saving GIF."])))
                    }
                }
            })
        }
    }

    
    private func saveAsImage() -> UIImage {
        let canvasSize = CGSize(width: template.canvas.width, height: template.canvas.height)
        
        let rendered = renderCanvasImage(templateSize: canvasSize,
                                         layers: layers,
                                         scale: UIScreen.main.scale
                                         
                                         
        )
        
        return rendered
    }
    
    private func saveAsJpeg(image: UIImage){
        fileVm.createFileWithJpeg(image: image)
    }
    
    private func saveAsPng(image: UIImage){
        fileVm.createFileWidthPng(image: image)
    }
    
    private func saveAsPdf(image: UIImage){
        fileVm.createFileWithPdf(image: image)
    }
  
       
    func renderCanvasImage(templateSize: CGSize, layers: [EditableLayer], scale: CGFloat = UIScreen.main.scale) -> UIImage {
        let targetSize = CGSize(width: templateSize.width, height: templateSize.height)
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = scale
        rendererFormat.opaque = false

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: rendererFormat)
        
        
        let img = renderer.image { ctx in
            // coordinate system origin at top-left; units are canvas units
            let gc = ctx.cgContext
            print("1 in")
            gc.setFillColor(UIColor.clear.cgColor)
            print("2 in")
            gc.fill(CGRect(origin: .zero, size: targetSize))
            
            print("3 in")

            for layer in layers {
                drawLayer(layer, in: gc, canvasSize: targetSize)
            }
            
            if watermarkEnabled, let wm = loadWatermarkImage(named: watermarkImageName) {
                // watermarkSizeInCanvas and padding are canvas units
                drawWatermark(in: gc,
                              canvasSize: targetSize,
                              watermark: wm,
                              sizeInCanvas: watermarkSizeInCanvas,
                              paddingInCanvas: watermarkPaddingInCanvas,
                              opacity: watermarkOpacity)
            }
        }
        return img
    }
    
 
    fileprivate func renderAnimatedGIF(templateSize: CGSize,
                                       layers: [EditableLayer],
                                       animation: FooterAnim,
                                       duration: Double = 2.0,
                                       fps: Int = 24,
                                       stagger: Double = 0.08,
                                       loopCount: Int = 0,
                                       watermarkEnabled: Bool = false,
                                       watermarkImageName: String = "",
                                       watermarkSizeInCanvas: CGFloat = 0,
                                       watermarkPaddingInCanvas: CGFloat = 0,
                                       watermarkOpacity: CGFloat = 1.0,
                                       extType: String,
                                       completion: @escaping (Result<URL, Error>) -> Void)
    {
        Task {
            // run heavy work off main thread
            await withCheckedContinuation { cont in
                DispatchQueue.global(qos: .userInitiated).async {
                    let frameCount = max(1, Int(Double(fps) * duration))
                    let frameDelay = 1.0 / Double(fps)

                    // prepare destination
                    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
                    let outURL = tempDir.appendingPathComponent("template_export_\(Int(Date().timeIntervalSince1970))\(extType)")
                    guard let dst = CGImageDestinationCreateWithURL(outURL as CFURL, kUTTypeGIF, frameCount, nil) else {
                        cont.resume()
                        completion(.failure(NSError(domain: "GIF", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create GIF destination."])))
                        return
                    }

                    // GIF properties (loop)
                    let gifProps = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: loopCount]] as CFDictionary
                    CGImageDestinationSetProperties(dst, gifProps)

                    let canvas = templateSize
                    let rendererFormat = UIGraphicsImageRendererFormat()
                    rendererFormat.scale = 1.0 // treat template units as points for pixel-perfect
                    rendererFormat.opaque = false
                    let renderer = UIGraphicsImageRenderer(size: canvas, format: rendererFormat)

                    // Precompute text layer indices order (we animate text layers only)
                    let textLayerIndices = layers.enumerated().filter { _, l in
                        if case .text = l.kind { return true } else { return false }
                    }
                    let idsOrder = textLayerIndices.map { $0.offset } // indices into layers array
                    let totalToAnimate = idsOrder.count

                    for frameIndex in 0..<frameCount {
                        let t = Double(frameIndex) * frameDelay // time in seconds
                        // Render frame
                        let img = renderer.image { ctx in
                            let gc = ctx.cgContext
                            // clear background white (optional)
                            gc.setFillColor(UIColor.white.cgColor)
                            gc.fill(CGRect(origin: .zero, size: canvas))

                            // For each layer (draw order) compute anim state if it's a text layer
                            for (i, layer) in layers.enumerated() {
                                if let idxInOrder = idsOrder.firstIndex(of: i) {
                                    // compute anim for this text layer using its index in idsOrder
                                    let state = animStateForLayer(at: t, index: idxInOrder, total: totalToAnimate, animation: animation, duration: duration, stagger: stagger)
                                    drawLayerWithAnim(layer, in: gc, canvasSize: canvas, opacity: state.opacity, scale: state.scale, offset: state.offset)
                                } else {
                                    // not animated (image or non-text)
                                    drawLayerWithAnim(layer, in: gc, canvasSize: canvas, opacity: 1.0, scale: 1.0, offset: .zero)
                                }
                            }
                            
                            if watermarkEnabled, let wm = loadWatermarkImage(named: watermarkImageName) {
                                // watermarkSizeInCanvas and padding are canvas units
                                drawWatermark(in: gc,
                                              canvasSize: canvas,
                                              watermark: wm,
                                              sizeInCanvas: watermarkSizeInCanvas,
                                              paddingInCanvas: watermarkPaddingInCanvas,
                                              opacity: watermarkOpacity)
                            }
                        }

                        guard let cg = img.cgImage else { continue }
                        // frame delay property
                        let frameProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: frameDelay]] as CFDictionary
                        CGImageDestinationAddImage(dst, cg, frameProperties)
                    }

                    // finalize
                    if CGImageDestinationFinalize(dst) {
                        cont.resume()
                        completion(.success(outURL))
                    } else {
                        cont.resume()
                        completion(.failure(NSError(domain: "GIF", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize GIF."])))
                    }
                }
            }
        }
    }
    
    fileprivate func animStateForLayer(at time: Double,
                                       index: Int,
                                       total: Int,
                                       animation: FooterAnim,
                                       duration: Double,
                                       stagger: Double) -> (opacity: Double, scale: CGFloat, offset: CGSize)
    {
        // Find per-layer delay and local progress (0..1)
        let delay = Double(index) * stagger
        let localT = max(0, min(1, (time - delay) / max(0.00001, (duration - Double(total) * stagger))))
        switch animation {
        case .FadeIn:
            let opacity = easeOutCubic(localT)
            return (opacity: opacity, scale: 1.0, offset: .zero)
        case .ZoomIn:
            let p = easeOutCubic(localT)
            let scale = CGFloat(0.25 + 0.75 * p) // 0.25 -> 1.0
            return (opacity: p, scale: scale, offset: .zero)
        case .BounceIn:
            // start offset upwards and large scale -> spring to 1
            let p = easeOutBack(localT, overshoot: 1.2)
            let scale = CGFloat(1.2 - 0.2 * p) // 1.2 -> 1.0
            let yOffset = CGFloat((1 - p) * -36.0) // -36 -> 0
            return (opacity: p, scale: scale, offset: CGSize(width: 0, height: yOffset))
        }
    }

    fileprivate func easeOutBack(_ t: Double, overshoot: Double = 1.25) -> Double {
        // back easing, overshoot >1
        let s = overshoot
        let p = t - 1
        return 1 + p * p * ((s + 1) * p + s)
    }
    fileprivate func easeOutExpo(_ t: Double) -> Double {
        return t >= 1 ? 1 : 1 - pow(2, -10 * t)
    }


    
    private func drawLayer(_ layer: EditableLayer, in gc: CGContext, canvasSize: CGSize) {
        // calculate rect in canvas coordinate space
        
        print("k 1")
        let rect = CGRect(x: layer.x, y: layer.y, width: layer.width, height: layer.height)

        
        print("k 2")
        // Save context state
        gc.saveGState()
        
        print("k 3")
        // Translate to layer center (for rotation & scale)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        print("k 4")
        gc.translateBy(x: center.x, y: center.y)
        
        print("k 5")

        // Apply rotation (degrees -> radians)
        let angle = (layer.rotation) * CGFloat.pi / 180.0
        
        print("k 6")
        if angle != 0 {
            gc.rotate(by: angle)
        }
        
        print("k 7 ")

        // Apply scale (uniform) - scale about center
        if layer.scale != 0 && layer.scale != 1 {
            gc.scaleBy(x: layer.scale, y: layer.scale)
        }
        
        print("k 8")

        // After transforms, draw content around centered origin.
        // So draw into a rect centered at origin:
        let drawRect = CGRect(x: -rect.width/2.0, y: -rect.height/2.0, width: rect.width, height: rect.height)
        
        print("k 9")

        switch layer.kind {
        case .image(let src):
            // draw image named src (try src then layer.name)
            if let name = src {
                // respect aspect fill / fit? Your layers were probably sized by Figma; draw to fill drawRect
                print("k 10")
                gc.saveGState()

                gc.setAlpha(layer.opacity)   // 0.0 → 1.0

                name.draw(in: drawRect)

                gc.restoreGState()
            
            } else {
                // fallback: draw placeholder rect
                gc.setFillColor(UIColor(white: 0.9, alpha: 1).cgColor)
                
                gc.fill(drawRect)
            }

        case .text(let props):
            // Build attributes: color + font
            
            print("k 11")
//            let uiColor = UIColor(red: CGFloat(props.color.r), green: CGFloat(props.color.g), blue: CGFloat(props.color.b), alpha: CGFloat(props.color.a))
            // Try font by exact asset name "Family-Weight" or family only; fallback to system
    
            print("k 12")
            
            
            func magic(from color: Color?) -> UIColor {
                 if let c = color {
                     #if canImport(UIKit)
                     return UIColor(c)
                     #else
                     return UIColor.black
                     #endif
                 } else {
                     return UIColor.black
                 }
             }
            let uiColor = magic(from: props.color.swiftUIColor)
            
            
    
            let font: UIFont = {
                let cleanedFamily = props.fontFamily.replacingOccurrences(of: " ", with: "")
              

                // Try "Family-Weight"
                let fw = props.fontFamily
                if let f = UIFont(name: fw, size: props.fontSize) {
                    return f
                }

                // Try family only
                if let f = UIFont(name: cleanedFamily, size: props.fontSize) {
                    return f
                }

                // Map weight string
            

                // SYSTEM fallback (never nil)
                return UIFont.systemFont(ofSize: props.fontSize, weight: .regular)
            }()

            print("k 13")
            // Paragraph style for alignment
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = {
                switch props.hAlign {
                case .left: return .left
                case .center: return .center
                case .right: return .right
                case .justify: return .justified
                }
            }()
            
            print("k 14")
            
            
            let shadow = NSShadow()
            if let sColor = props.shadowColor {
                shadow.shadowColor = magic(from: sColor)
              } else {
                  shadow.shadowColor = nil
              }
            shadow.shadowOffset = CGSize(width: props.shadowX, height: props.shadowY)
            
            print(props.shadowBlur)
            shadow.shadowBlurRadius = props.shadowBlur * 3

            paragraph.lineBreakMode = .byWordWrapping
            paragraph.lineSpacing = 0
            
            let underline = props.underline ? NSUnderlineStyle.single.rawValue : 0
            let strike    = props.small ? NSUnderlineStyle.single.rawValue : 0


            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: uiColor.withAlphaComponent(layer.opacity / 255.0),
                .paragraphStyle: paragraph,
                .shadow: shadow,
                .underlineStyle: underline, // bool
                .strikethroughStyle: strike,
                .kern: props.space
            ]
            
            print("k 15")

            let ns = NSString(string: props.capital ? props.text.uppercased() : props.text)
            // When drawing text, we should consider vertical alignment. We'll draw into drawRect sized rect.
            let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
            
            let cgSize = CGSize(width: drawRect.width, height: CGFloat.greatestFiniteMagnitude)
            
            print("k 16")
            let textRect = ns.boundingRect(with: cgSize,
                                           options: options,
                                           attributes: attrs,
                                           context: nil)

//            let textSize = ns.size(withAttributes: attrs)
//            let textRect = CGRect(origin: .zero, size: textSize)
            print("k 17")

            // Vertical alignment: top/center/bottom
            var yOffset: CGFloat = 0
            switch props.vAlign {
            case .top: yOffset = -rect.height/2.0
            case .center: yOffset = -textRect.height/2.0
            case .bottom: yOffset = rect.height/2.0 - textRect.height
            }

            // Horizontal alignment handled by paragraphStyle; we must compute x origin accordingly
            // drawRect origin is (-w/2, -h/2). We'll set drawOrigin.x so text aligns inside drawRect per paragraph.
            let drawOrigin = CGPoint(x: drawRect.minX, y: yOffset)
            let drawBounding = CGRect(origin: drawOrigin, size: CGSize(width: drawRect.width, height: textRect.height))
            
            

//            ns.draw(at: drawOrigin, withAttributes: attrs)
            ns.draw(with: drawBounding, options: options, attributes: attrs, context: nil)
            
            print("k 17")
        }

        // Restore context state to continue drawing next layer
        gc.restoreGState()
    }
    
    fileprivate func drawLayerWithAnim(_ layer: EditableLayer, in gc: CGContext, canvasSize: CGSize,
                                       opacity: Double, scale: CGFloat, offset: CGSize)
    {
        // compute rect in canvas coords
        var rect = CGRect(x: layer.x, y: layer.y, width: layer.width, height: layer.height)
        gc.saveGState()

        // Translate to center
        let center = CGPoint(x: rect.midX, y: rect.midY)
        gc.translateBy(x: center.x + offset.width, y: center.y + offset.height)

        // Apply rotation
        let angle = (layer.rotation) * CGFloat.pi / 180.0
        if angle != 0 {
            gc.rotate(by: angle)
        }

        // Apply combined scale: layer.scale * frame scale
        let finalScale = (layer.scale == 0 ? 1 : layer.scale) * scale
        if finalScale != 1 {
            gc.scaleBy(x: finalScale, y: finalScale)
        }

        // Apply alpha
        gc.setAlpha(CGFloat(opacity))

        // draw centered
        let drawRect = CGRect(x: -rect.width/2.0, y: -rect.height/2.0, width: rect.width, height: rect.height)

        switch layer.kind {
        case .image(let src):
            if let name = src {
                name.draw(in: drawRect)
            } else {
                gc.setFillColor(UIColor(white: 0.92, alpha: 1).cgColor)
                gc.fill(drawRect)
            }

        case .text(let props):
            let uiColor = UIColor(red: CGFloat(props.color.r), green: CGFloat(props.color.g), blue: CGFloat(props.color.b), alpha: CGFloat(props.color.a))
            // safe font builder
            let font: UIFont = {
                let cleanedFamily = props.fontFamily.replacingOccurrences(of: " ", with: "")
                let cleanedWeight = props.fontWeight.replacingOccurrences(of: " ", with: "")

                // Try "Family-Weight"
                let fw = props.fontFamily
                if let f = UIFont(name: fw, size: props.fontSize) {
                    return f
                }

                // Try family only
                if let f = UIFont(name: cleanedFamily, size: props.fontSize) {
                    return f
                }

                // Map weight string
            

                // SYSTEM fallback (never nil)
                return UIFont.systemFont(ofSize: props.fontSize, weight: .regular)
            }()

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = {
                switch props.hAlign {
                case .left: return .left
                case .center: return .center
                case .right: return .right
                case .justify: return .justified
                }
            }()
            paragraph.lineBreakMode = .byWordWrapping

            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: uiColor,
                .paragraphStyle: paragraph
            ]

            let ns = NSString(string: props.text)
            let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
            // limit width to drawRect.width
            let textRect = ns.boundingRect(with: CGSize(width: drawRect.width, height: CGFloat.greatestFiniteMagnitude),
                                           options: options, attributes: attrs, context: nil)
            // vertical align
            var yOffset: CGFloat = -drawRect.height/2.0
            switch props.vAlign {
            case .top: yOffset = -drawRect.height/2.0
            case .center: yOffset = -textRect.height/2.0
            case .bottom: yOffset = drawRect.height/2.0 - textRect.height
            }
            let drawOrigin = CGPoint(x: drawRect.minX, y: yOffset)
            let drawBounding = CGRect(origin: drawOrigin, size: CGSize(width: drawRect.width, height: textRect.height))
            ns.draw(with: drawBounding, options: options, attributes: attrs, context: nil)
        }

        gc.restoreGState()
    }

    
    func saveImageToPhotos(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        // check authorization
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        // proceed
                        doSave()
                    } else {
                        completion(.failure(NSError(domain: "PhotoAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied."])))
                    }
                }
            }
        } else if status == .authorized || status == .limited {
            doSave()
        } else {
            completion(.failure(NSError(domain: "PhotoAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied."])))
        }

        func doSave() {
            PHPhotoLibrary.shared().performChanges({
                // create asset request
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(.success(()))
                    } else {
                        completion(.failure(error ?? NSError(domain: "SaveImage", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown error saving image."])))
                    }
                }
            })
        }
    }
    
    func mapTexttoLayer(input: String,rect: CGRect,x: CGFloat,y: CGFloat,fontSize: CGFloat) -> EditableLayer{
        
        let textProp = EditableLayer.TextProps(
            color: ColorValue(r: 0, g: 0, b: 0, a: 1),
            fontSize: fontSize, fontFamily:  "Poppins-Regular", fontWeight: "Bold",
            hAlign: .center, vAlign: .center, text: input)
        
 
        let layer = EditableLayer(id: UUID(), name: "Text", kind: .text(textProp), x: x, y: y, width: rect.width, height: rect.height, rotation: 0, scale: 1)
        
        return layer
    }
    
    func mapImageToLayer(input: UIImage,width: CGFloat,height: CGFloat,x: CGFloat,y: CGFloat) -> EditableLayer{
        
        
        
        
        let layer = EditableLayer(id: UUID(), name: "Image", kind: .image(src: input), x: x, y: y, width: width, height: height, rotation: 0, scale: 1)
        
        return layer
    }
    
    fileprivate func easeOutCubic(_ t: Double) -> Double {
        let p = t - 1
        return 1 + p * p * p
    }

    
    func getTextWidth(input: String,space: CGFloat = 0,font: String,fontSize: CGFloat,isBold: Bool = false,isItalic: Bool = false
                      ) -> CGRect{
        
        
//        var addition = ""
//        if isBold && isItalic{
//            addition = "BoldItalic"
//        }else if isBold{
//            addition = "Bold"
//        }else if isItalic{
//            addition = "Italic"
//        }else{
//            addition = "Regular"
//        }
        let ns = NSString(string: input.uppercased())
        
        let font = UIFont(name: font, size: fontSize)
        
 
        let attributes: [NSAttributedString.Key: Any] = [.font: font ?? UIFont.systemFont(ofSize: fontSize),.kern: space]
        
        let textSize = ns.size(withAttributes: attributes)
        let textRect = CGRect(origin: .zero, size: textSize)
        
        
        
        return textRect
    }
    
    
    private func map(_ mode: ScaleMode) -> TemplateView.ScaleMode {
        switch mode { case .aspectFit: .aspectFit; case .aspectFill: .aspectFill; case .stretch: .stretch }
    }
    
    private func undo() {
        guard let prev = undoStack.popLast() else { return }
        // push current into redo
        redoStack.append(layers.map { $0 })
        layers = prev
    }
    private func redo() {
        guard let next = redoStack.popLast() else { return }
        // push current into undo
        undoStack.append(layers.map { $0 })
        layers = next
    }
    
    private func beginAtomicChange(action: String) {
          // only push the snapshot once at the beginning of a session
          if !changeSessionActive {
              pushState(action: action)
              changeSessionActive = true
          }
          // reset any existing timer (we'll end session after idle)
          changeSessionTimer?.invalidate()
          changeSessionTimer = nil
      }
    
    private func scheduleEndAtomicChange() {
        changeSessionTimer?.invalidate()
        changeSessionTimer = Timer.scheduledTimer(withTimeInterval: changeSessionIdle, repeats: false) { _ in
            endAtomicChange()
        }
        RunLoop.current.add(changeSessionTimer!, forMode: .common)
    }
    
    private func endAtomicChange() {
        changeSessionTimer?.invalidate()
        changeSessionTimer = nil
        changeSessionActive = false
    }
    
    private func pushState(action: String = "change") {
        // push a deep copy (EditableLayer is struct so shallow copy is fine)
        undoStack.append(layers.map { $0 })
        // clear redo when new action occurs
        redoStack.removeAll()
        
        print("undo size \(undoStack.count)")

    }
    
}

struct NewTemplatePanelView: View {
    
    @Binding var layers: [EditableLayer]
    
    var onMove: ((_ from: IndexSet, _ to: Int) -> Void)? = nil

    var body: some View {
        List {
            ForEach(layers) { layer in
                HStack {
             

                    VStack(alignment: .leading) {
                        Text(layer.name).font(.headline)

                        switch layer.kind {
                        case .image:
                            Text("Image").font(.caption).foregroundColor(.secondary)
                        case .text(let text):
                            Text(text.text)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
            }
            .onMove(perform: move)
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        if let onMove = onMove {
            // Let parent handle state snapshot and the move itself (so undo works there).
            onMove(source, destination)
        } else {
            // No callback — perform the move directly
            layers.move(fromOffsets: source, toOffset: destination)
        }
    }
}


fileprivate struct LayoutMapper {
    let canvas: CGSize
    let container: CGSize
    let mode: TemplateView.ScaleMode = .aspectFit
    
    let scaleX: CGFloat
    let scaleY: CGFloat
    let scale: CGFloat
    let contentSize: CGSize
    
    init(canvas: CGSize, container: CGSize, mode: TemplateView.ScaleMode) {
        self.canvas = canvas
        self.container = container
        switch mode {
        case .stretch:
            scaleX = container.width / max(canvas.width, 0.0001)
            scaleY = container.height / max(canvas.height, 0.0001)
            scale = 1
            contentSize = container
        case .aspectFill:
            let s = max(container.width / max(canvas.width, 0.0001),
                        container.height / max(canvas.height, 0.0001))
            scaleX = s; scaleY = s; scale = s
            contentSize = CGSize(width: canvas.width * s, height: canvas.height * s)
        case .aspectFit:
            let s = min(container.width / max(canvas.width, 0.0001),
                        container.height / max(canvas.height, 0.0001))
            scaleX = s; scaleY = s; scale = s
            contentSize = CGSize(width: canvas.width * s, height: canvas.height * s)
        }
    }
    
    func mapRect(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> CGRect {
        switch mode {
        case .stretch:
            return CGRect(x: x * scaleX, y: y * scaleY, width: w * scaleX, height: h * scaleY)
        case .aspectFill, .aspectFit:
            let rect = CGRect(x: x * scale, y: y * scale, width: w * scale, height: h * scale)
            return rect
        }
    }
}

fileprivate struct LayerRender: View {
    let layer: EditableLayer
    let animState: LayerAnimState?
    let scale: CGFloat

    init(layer: EditableLayer, animState: LayerAnimState? = nil,scale: CGFloat) {
        self.layer = layer
        self.animState = animState
        self.scale = scale
    }

    
    var body: some View {
        switch layer.kind {
        case .image(let src):
            LayerImageView(imageName: src)
                .opacity(layer.opacity / 255.0)
                .clipped()
        case .text(let p):
            
            LayerTextView(
                text: p.text,
                color: p.color.swiftUIColor,
                fontFamily: p.fontFamily,
                isBold: p.bold,
                isItalic: p.italic,
                isCapitalized: p.capital,
                isSmall: p.small,
                underline: p.underline,
                space: p.space,
                showShadow: p.shadow,
                shadowColor: p.shadowColor ?? Color(.sRGBLinear, white: 0, opacity: 0.33),
                shadowX: p.shadowX,
                shadowY: p.shadowY,
                blur: p.shadowBlur,
                fontSize: p.fontSize * scale,
                weight: p.fontWeight,
                hAlign: p.hAlign,
                vAlign: p.vAlign
            )
            .opacity(layer.opacity / 255.0)
            .scaleEffect(animState?.scale ?? 1.0)
            .offset(animState?.offset ?? .zero)
    
            
        }
    }
}

fileprivate struct SelectionOverlay: View {
    let isSelected: Bool
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .stroke(style: StrokeStyle(lineWidth: isSelected ? 2 : 0, dash: [6, 4]))
            .foregroundStyle(isSelected ? Color.accentColor : .clear)
    }
}

fileprivate struct LayerImageView: View {
    let imageName: UIImage?
    var body: some View {
        #if os(iOS)
        if let ui = imageName {
            Image(uiImage: ui).resizable().interpolation(.high)
        } else {
            Color.clear.overlay(Text("Missing: \(imageName)").font(.caption).foregroundColor(.red))
        }
        #else
        if let ns = NSImage(named: imageName) {
            Image(nsImage: ns).resizable().interpolation(.high)
        } else {
            Color.clear.overlay(Text("Missing: \(imageName)").font(.caption).foregroundColor(.red))
        }
        #endif
    }
}

fileprivate struct LayerTextView: View {
    
    let text: String
    let color: Color
    let fontFamily: String
    let isBold: Bool
    let isItalic: Bool
    let isCapitalized: Bool
    let isSmall: Bool
    let underline: Bool
    let space: CGFloat
    let showShadow: Bool
    var shadowColor: Color
    let shadowX:CGFloat
    let shadowY:CGFloat
    let blur: CGFloat
    


    let fontSize: CGFloat
    let weight: String
    let hAlign: HorizontalAlign
    let vAlign: VerticalAlign

    
    private var displayText: String {
        var t = text
        if isCapitalized {
            t = t.uppercased()
        }
        return t
    }

    
    var body: some View {
        
        
               // multiline alignment for Text view
               let multiline: TextAlignment = {
                   switch hAlign {
                   case .left: return .leading
                   case .center: return .center
                   case .right: return .trailing
                   case .justify: return .leading
                   }
               }()

  
        ZStack(alignment: Alignment(horizontal: hAlign.swiftUI, vertical: vAlign.swiftUI)) {

            Text(displayText)
                .foregroundColor(color)
                .font(.custom(fontFamily, size: fontSize))
                .underline(underline)
                .strikethrough(isSmall, color: color) // isSmall = cut line
                .multilineTextAlignment(multiline)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: false)
                .kerning(space)
                .shadow(color: showShadow ? shadowColor : .black,
                               radius: showShadow ? blur : 0,
                               x: showShadow ? shadowX : 0,
                               y: showShadow ? shadowY : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: Alignment(horizontal: hAlign.swiftUI, vertical: vAlign.swiftUI))
            
       
            
        }
        .onAppear(perform: {
            print("font family \(fontFamily)")
        })
    }
    


}

fileprivate extension HorizontalAlign {
    var swiftUI: HorizontalAlignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right, .justify: return .trailing
        }
    }
}
fileprivate extension VerticalAlign {
    var swiftUI: VerticalAlignment {
        switch self {
        case .top: return .top
        case .center: return .center
        case .bottom: return .bottom
        }
    }
}

fileprivate func layerHitTest(_ layer: EditableLayer, tapInContainer p: CGPoint, layout: LayoutMapper) -> Bool {
    // Layer rect in container coordinates (pre-transform)
    
    let rect   = layout.mapRect(x: layer.x, y: layer.y, w: layer.width, h: layer.height)
      let center = CGPoint(x: rect.midX, y: rect.midY)

      // Step 1: undo position (shift to layer-centered coords)
      var local = CGPoint(x: p.x - center.x, y: p.y - center.y)

      // Step 2: undo rotation
      let theta = CGFloat(layer.rotation) * .pi / 180
      let cosT = cos(-theta), sinT = sin(-theta)
      let rx = local.x * cosT - local.y * sinT
      let ry = local.x * sinT + local.y * cosT
      local = CGPoint(x: rx, y: ry)

      // Step 3: undo scale (uniform)
      let s = layer.scale == 0 ? 1 : layer.scale
      local = CGPoint(x: local.x / s, y: local.y / s)

      // Bring back to content space centered at 'center'
      local = CGPoint(x: local.x + center.x, y: local.y + center.y)

      // Test against the pre-transform rect
      return rect.contains(local)
    
//    return rect.contains(local)
}





