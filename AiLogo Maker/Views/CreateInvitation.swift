//
//  CreateInvitation.swift
//  InvitationMaker
//
//  Created by Apple on 06/12/2025.
//

import SwiftUI
import Photos

struct CreateInvitation: View {
    
    
    @AppStorage("pro") private var isPro = false
    @EnvironmentObject var route: NavigationRouter
    @Environment(\.dismiss) var dismiss
    @State var layers:[InvitationLayer] = []
    @State private var layerAnimations: [UUID: LayerAnimState] = [:]
    @EnvironmentObject var vm: EditorViewModel
    @State private var selectedID: UUID? = nil
    @State var addText: String = ""
    @State var editText: String = ""
    @State var showAddText = false
    @State var showEditText = false
    @State var controlKind: ControlKind? = nil
    @State var currentControll: ControlKind? = nil
    @State private var undoStack: [[InvitationLayer]] = []
    @State private var redoStack: [[InvitationLayer]] = []
    @State private var changeSessionActive: Bool = false
    @State private var actionBackground: Bool = false
    @State private var bgImage: UIImage?
    @State private var changeSessionTimer: Timer? = nil
    private let changeSessionIdle: TimeInterval = 0.35
    @State private var showLayerPanel = false
    @State private var bgColor = Color(hex: 0xD7DDEC)
    @State private var canvasSize: CGSize = .zero
    @State private var screenshotImage: UIImage?
    @State private var watermarkEnabled: Bool = true
    @State private var watermarkImageName: String = "watermark_icon" // asset name in bundle
    @State private var watermarkOpacity: CGFloat = 0.85
    @State private var watermarkSizeInCanvas: CGFloat = 40
    @State private var watermarkPaddingInCanvas: CGFloat = 12
    @State private var showSaveAlert = false
    @State private var saveResult = false
    @State private var message = ""
    @EnvironmentObject var saveVm: SaveViewModel
    @EnvironmentObject var fileVm: FileViewModel
    @State private var isLoading = false
    @State private var showWaterAlert = false
    @State private var showReward = true
    @State private var adLoading = false
    @State private var showAlert = false
    @State private var adWaterMark = false

    var body: some View {
        VStack(spacing: 0){
            
            HStack{
                
                Image("back_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30,height: 30)
                    .onTapGesture {
                        
                        dismiss()
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
                        
                        
                 
                        isLoading = true
                        let path = saveAsImage()
                        route.push(Route.Save(path))
                        isLoading = false
                    }
            }
            .padding(.horizontal)
            
                        
            GeometryReader { geo in

                ZStack {
                    
                    ForEach(layers) { layer in
                        
                        let rect = CGRect(x: layer.x, y: layer.y, width: layer.width, height: layer.height)
                        
                        
                        ZStack{
                            
                            LayerRender(layer: layer, animState: layerAnimations[layer.id])
                                .frame(width: layer.width, height: layer.height, alignment: .center)
                            SelectionOverlay(isSelected: layer.id == selectedID)
                                .frame(width: rect.width, height: rect.height)
                        }
                        .scaleEffect(layer.scale)
                        .rotationEffect(.degrees(layer.rotation), anchor: .center)
                        .position(x: layer.x, y: layer.y)
                        .contentShape(Rectangle())
                    }
                    
                    
                    
                }
                .position(x: geo.size.width/2, y: geo.size.height/2)
                .clipped()
                .background(bgColor)
                .overlay(
                    Group {
                        
                        if watermarkEnabled, let wm = loadWatermarkImage(named: watermarkImageName) {
                            
                            
                            ZStack{
                                
                                GIFWebView(gifName: "watermark_gif")
                                    .aspectRatio(contentMode: .fit)
                                    
                            }
                            .frame(width: watermarkSizeInCanvas,
                                   height: watermarkSizeInCanvas)
                            .padding(.bottom, watermarkPaddingInCanvas)
                            .padding(.trailing, watermarkPaddingInCanvas)
                            .onTapGesture{
                                showWaterAlert = true
                            }
                         
                        }
                    },
                    alignment: .bottomTrailing
                )
                
                .onAppear {
                    
              
                    watermarkEnabled = !isPro && !adWaterMark
                    canvasSize = geo.size
                    
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
                            
                            
                            
                            let p = CGPoint(x: value.location.x,
                                            y: value.location.y)
                            
                            // 2) test from top to bottom
                            if let idx = layers.indices.reversed().first(where: {
                                layerHitTest(layers[$0], tapInContainer: p)
                            }) {
                                
                                print("found")
                                selectedID = layers[idx].id
                                controlKind = .controlls
                                currentControll = .controlls
                                
                                
    
                                
                            } else {
                    
                                selectedID = nil
                                controlKind = nil
                                currentControll = nil
                            }
                        }
                )

            }
            .frame(height: 400)
            .padding(.top,10)
            


            
            
            
            
            
            
            VStack{
                
                ToolsArea(
                    controllSelected: controlKind,
                    selectedIdKind: 2,
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
                        
                        bgColor = color
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
                        guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return }
                        
                        if case .text(var textProperty) = layers[idx].kind {
                            // modify textProperty
                            
                            if font.isEmpty {
                                textProperty.font = nil
                            }else{
                                textProperty.font = font
                            }
                            
                            
                            print("font is \(textProperty.font ?? "none")")
                            let rect = getTextWidth(
                                input: textProperty.text,
                                space: textProperty.space,
                                font: textProperty.font ?? "Poppins-Regular",
                                isBold: textProperty.bold,
                                isItalic: textProperty.italic
                            )
                            
                            pushState(action: "Font")
                            layers[idx].kind = .text(textProperty)
                            layers[idx].width = rect.width
                            layers[idx].height = rect.height
                        }
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
                            
                            
                            textProperty.capital = !textProperty.capital
                            
                            pushState(action: "Capital")
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
         
                            beginAtomicChange(action: "color")
                            textProperty.color = color
                            layers[idx].kind = .text(textProperty)
                            scheduleEndAtomicChange()
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
                        guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return 0}
                        
                        
                        return layers[idx].opacity
                    
                    },
                    setOpacity: { v in
                        guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return}
                        
                        beginAtomicChange(action: "opacity")
                        layers[idx].opacity = v
                        scheduleEndAtomicChange()
                    
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
                            
                            let rect = getTextWidth(input: textProperty.text,space: textProperty.space)
                            
                            
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
                    selectedIdKind: 2,
                    showFont: true,
                    showImport: true,
                    currentControll: $currentControll,
                    actionText: {showAddText = true},
                    actionIcon: {route.push(Route.Icon)},
                    actionShape: {route.push(Route.Shape)},
                    actionBackground: {actionBackground = true},
                    actionImport: {actionBackground = true},
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
        .background(.white)
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showLayerPanel) {
            LayerInvitationPanelView(layers: $layers, onMove: { from, to in
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
        .saveDialog(isPresented: $showSaveAlert, onImage: {
            
            saveAsImage()
            showSaveAlert = false
        }, onGif: {
            
            showSaveAlert = false
            
        }, onCancel: {
            showSaveAlert = false
        })
        .watermarkDialog(isPresented: $showWaterAlert
                         ,showReward: showReward
                         , onPremium: {
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
        .alert("Alert", isPresented: $saveResult, actions: {
            Button("Ok", action: {
                saveResult = false
            })
        }, message: {
            Text(message)
        })
        .loadingDialog(isPresented: $isLoading)
        .imageSourceDialog(isPresented: $actionBackground){ path in
            
            if let image = UIImage(contentsOfFile: path.path){
                
                let x = (canvasSize.width) / 2
                let y = (canvasSize.height) / 2
                
                
                let layer = mapImageToLayer(input: image, width: image.size.width, height: image.size.height, x: x, y: y)
                
                
                pushState(action: "add")
                layers.append(layer)
            }
        }
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
                                        
                                  
                                        let rect = getTextWidth(input: editText)
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
                                    let rect = getTextWidth(input: addText)
                                    
                                    let x = (canvasSize.width) / 2
                                    let y = (canvasSize.height) / 2
                                    
                                    let layer = mapTexttoLayer(input: addText,
                                                               rect: rect,
                                                               x: x, y: y)
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
    
    
    private func saveAsImage() -> String{
        
        let viewToCapture = CanvasContentView(geo: canvasSize, layers: layers, layerAnimations: layerAnimations, bgColor: bgColor,
            watermarkEnabled: watermarkEnabled,
                                              waterMarkImage: watermarkImageName,
                                              watermarkOpacity: watermarkOpacity,
                                              watermarkSizeInCanvas: watermarkSizeInCanvas,
                                              watermarkPaddingInCanvas: watermarkPaddingInCanvas
        )
        

        let renderer = ImageRenderer(content: viewToCapture)
        renderer.proposedSize = .init(width: canvasSize.width, height: canvasSize.height)
        renderer.scale = UIScreen.main.scale
        if let image = renderer.uiImage {
            let path = fileVm.createTempFile(image: image)
            return "\(path)"
        }
        
        return ""
      
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
    
    
    fileprivate func loadWatermarkImage(named name: String) -> UIImage? {
        #if os(iOS)
        return UIImage(named: name)
        #else
        return NSImage(named: name) // macOS branch if needed
        #endif
    }
    
    
    private func saveAsImage(canvas: CGSize) {
        
      
        let canvasSize = CGSize(width: canvas.width, height: canvas.height)
        

        // choose scale = 1 (exact canvas pixels) or UIScreen.main.scale for retina.
        let rendered = renderCanvasImage(templateSize: canvasSize, layers: layers, scale: UIScreen.main.scale)
        
        saveImageToPhotos(rendered) { result in
            switch result {
            case .success:
                // show confirmation UI — e.g. toast or alert
                print("Saved to Photos")
                message = "Image saved to photos"
               
            case .failure(let error):
                print("Failed to save: \(error.localizedDescription)")
                message = "Image failed to save"
                saveResult = true
               
            }
        }
        
        print("4")
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
    
    func renderCanvasImage(templateSize: CGSize, layers: [InvitationLayer], scale: CGFloat = UIScreen.main.scale) -> UIImage {
        
        let targetSize = CGSize(width: templateSize.width, height: templateSize.height)
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.opaque = false
        rendererFormat.scale = scale

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
    
    private func drawLayer(_ layer: InvitationLayer, in gc: CGContext, canvasSize: CGSize) {
        // calculate rect in canvas coordinate space
        
        print("k 1")
        var rect   = CGRect(x: layer.x, y: layer.y, width: layer.width, height: layer.height)
        
        
        let midX = rect.width / 2.0
        let midY = rect.height / 2.0

        rect = CGRect(x: layer.x - midX, y: layer.y - midY, width: layer.width, height: layer.height)

        
        print("k 2")
        // Save context state
        gc.saveGState()
        
        let center = CGPoint(x: layer.x, y: layer.y)
        gc.translateBy(x: center.x, y: center.y)

        // rotation
        let angle = layer.rotation * .pi / 180
        if angle != 0 { gc.rotate(by: angle) }

        // scale
        if layer.scale != 0 && layer.scale != 1 { gc.scaleBy(x: layer.scale, y: layer.scale) }

        
        print("k 9")

        switch layer.kind {
        case .image(let src):
            // draw image named src (try src then layer.name)
            // draw image named src (try src then layer.name)
            
            print("layer")

        case .text(let props):
            // Build attributes: color + font
            
            print("k 11")
            
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
            let uiColor = magic(from: props.color)
            // Try font by exact asset name "Family-Weight" or family only; fallback to system
    
            print("k 12")
            
    
            let font: UIFont = {
           

                var addition = ""
                if props.italic && props.bold {
                    addition = "BoldItalic"
                }else if props.italic {
                    addition = "Italic"
                }else if props.bold {
                    addition = "Bold"
                }else{
                    addition = "Regular"
                }
                // Try "Family-Weight"
                let fw = props.font ?? "Poppings"
                if let f = UIFont(name: "\(fw)-\(addition)", size: 26) {
                    return f
                }

          

                // Map weight string
            

                // SYSTEM fallback (never nil)
                return UIFont.systemFont(ofSize: 26, weight: .regular)
            }()

            print("k 13")


            
            let shadow = NSShadow()
            if let sColor = props.shadowColor {
                shadow.shadowColor = magic(from: sColor)
              } else {
                  shadow.shadowColor = nil
              }
            shadow.shadowOffset = CGSize(width: props.shadowX, height: props.shadowY)
            shadow.shadowBlurRadius = props.shadowBlur
            
            
            let underline = props.underline ? NSUnderlineStyle.single.rawValue : 0
            let strike    = props.small ? NSUnderlineStyle.single.rawValue : 0
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: uiColor.withAlphaComponent(layer.opacity / 255.0),
                .shadow: shadow,
                .underlineStyle: underline, // bool
                .strikethroughStyle: strike,
                .kern: props.space
            ]
            
            print("k 15")

            let ns = NSString(string: props.text)
         
            let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
            
            
            let textHeight = ns.boundingRect(
                with: CGSize(width: layer.width, height: CGFloat.greatestFiniteMagnitude),
                options: options,
                attributes: attrs,
                context: nil
            ).height


            // draw rect centered at layer
            let textRect = CGRect(
                x: -layer.width/2,
                y: -textHeight/2,
                width: layer.width,
                height: textHeight
            )

            ns.draw(with: textRect, options: options, attributes: attrs, context: nil)

            
            print("k 19")
        }

        // Restore context state to continue drawing next layer
        gc.restoreGState()
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
    
    
    func getTextWidth(input: String,space: CGFloat = 0,font: String = "Poppins-BoldItalic",isBold: Bool = false,isItalic: Bool = false
                      ) -> CGRect{
        
        
        var addition = ""
        if isBold && isItalic{
            addition = "BoldItalic"
        }else if isBold{
            addition = "Bold"
        }else if isItalic{
            addition = "Italic"
        }else{
            addition = "Regular"
        }
        let ns = NSString(string: input.uppercased())
        
        let font = UIFont(name: "\(font)-\(addition)", size: 26)
        
 
        let attributes: [NSAttributedString.Key: Any] = [.font: font ?? UIFont.systemFont(ofSize: 26),.kern: space]
        
        let textSize = ns.size(withAttributes: attributes)
        let textRect = CGRect(origin: .zero, size: textSize)
        
        
        
        return textRect.insetBy(dx: -10, dy: -10)
    }
    
    func mapTexttoLayer(input: String,rect: CGRect,x: CGFloat,y: CGFloat) -> InvitationLayer{
        
        let textProp = InvitationLayer.TextProps(text: input)
        let layer = InvitationLayer(id: UUID(), name: "Text", kind: .text(textProp), x: x, y: y, width: rect.width, height: rect.height, rotation: 0, scale: 1)
        
        return layer
    }
    
    func mapImageToLayer(input: UIImage,width: CGFloat,height: CGFloat,x: CGFloat,y: CGFloat) -> InvitationLayer{
        
        
        
        
        let layer = InvitationLayer(id: UUID(), name: "Image", kind: .image(src: input), x: x, y: y, width: width, height: height, rotation: 0, scale: 1)
        
        return layer
    }
    
    
}

struct CanvasContentView: View {
    let geo: CGSize // Pass the geometry proxy to get the size
    let layers: [InvitationLayer] // Assuming LayerModel is your data type
    let layerAnimations: [UUID: LayerAnimState]
    let bgColor: Color
    let watermarkEnabled: Bool
    let waterMarkImage: String
    let watermarkOpacity: CGFloat
    let watermarkSizeInCanvas: CGFloat
    let watermarkPaddingInCanvas: CGFloat

    var body: some View {
        
        ZStack {
            
            ForEach(layers) { layer in

                ZStack{
                    
                    LayerRender(layer: layer, animState: layerAnimations[layer.id])
                        .frame(width: layer.width, height: layer.height, alignment: .center)
             
                }
                .scaleEffect(layer.scale)
                .rotationEffect(.degrees(layer.rotation), anchor: .center)
                .position(x: layer.x, y: layer.y)
                .contentShape(Rectangle())
            }
        }
        .position(x: geo.width/2, y: geo.height/2)
        .background(bgColor)
        .overlay(
            Group {
                if watermarkEnabled {
                    
                    
                    ZStack{
                        
                        Image("waterMarkImage")
                            .aspectRatio(contentMode: .fit)
                            
                    }
                    .frame(width: watermarkSizeInCanvas,
                           height: watermarkSizeInCanvas)
                    .padding(.bottom, watermarkPaddingInCanvas)
                    .padding(.trailing, watermarkPaddingInCanvas)
                 
                 
                }
            },
            alignment: .bottomTrailing
        )
        .clipped()
        
        .onAppear {
            print("size \(geo)")
        }
        
        

    }
}

fileprivate struct LayerRender: View {
    let layer: InvitationLayer
    let animState: LayerAnimState?
    
    init(layer: InvitationLayer, animState: LayerAnimState? = nil) {
        self.layer = layer
        self.animState = animState
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
                color: p.color ?? Color.black,
                fontFamily: p.font ?? "",
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
                blur: p.shadowBlur
            )
            .opacity(layer.opacity / 255.0)
            .scaleEffect(animState?.scale ?? 1.0)
            .offset(animState?.offset ?? .zero)
            
            
        }
    }
}

struct LayerAnimState {
    var opacity: Double = 1.0
    var scale: CGFloat = 1.0
    var offset: CGSize = .zero
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
    
    
  
    
    private var baseName: String {
        fontFamily.isEmpty ? "Poppins" : fontFamily
    }
    
    private var displayText: String {
        var t = text
        if isCapitalized {
            t = t.uppercased()
        }
        return t
    }
    
    private var fontName: String {
        var addition = ""
        if isBold && isItalic{
            addition = "BoldItalic"
        }else if isBold{
            addition = "Bold"
        }else if isItalic{
            addition = "Italic"
        }else{
            addition = "Regular"
        }
        
        return "\(fontFamily)-\(addition)"
    }
    
    
    
    
    var body: some View {

        Text(displayText)
            .foregroundColor(color)
            .font(.custom(fontName, size: 26))
            .underline(underline)
            .strikethrough(isSmall, color: color) // isSmall = cut line
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: true, vertical: false)
            .kerning(space)
            .shadow(color: showShadow ? shadowColor : .black,
                           radius: showShadow ? blur : 0,
                           x: showShadow ? shadowX : 0,
                           y: showShadow ? shadowY : 0)
            

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

fileprivate func layerHitTest(_ layer: InvitationLayer, tapInContainer p: CGPoint) -> Bool {
    // Layer rect in container coordinates (pre-transform)
    
    
    
    
    var rect   = CGRect(x: layer.x, y: layer.y, width: layer.width, height: layer.height)
    
    
    let midX = rect.width / 2
    let midY = rect.height / 2
    
    print("\(rect.minX) \(rect.minY) \(rect.maxX) \(rect.maxY) \(midX) \(midY)")
    

    
    rect = CGRect(x: layer.x - midX, y: layer.y - midY, width: layer.width, height: layer.height)
    
    print("\(rect.minX) \(rect.minY) \(rect.maxX) \(rect.maxY) \(p)")
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
    
    let result = rect.contains(local)
    print(result)
    return result
    
    //    return rect.contains(local)
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
        let s = min(container.width / max(canvas.width, 0.0001),
                    container.height / max(canvas.height, 0.0001))
        scaleX = s; scaleY = s; scale = s
        contentSize = CGSize(width: canvas.width * s, height: canvas.height * s)
    }
    
    func mapRect(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> CGRect {
        let rect = CGRect(x: x * scale, y: y * scale, width: w * scale, height: h * scale)
        return rect
    }
}



struct ToolsArea: View{
    

    
    let controllSelected: ControlKind?
    let selectedIdKind: Int
    let isUndoEmpty: Bool
    let isRedoEmpty: Bool
    let actionUndo: () -> Void
    let actionRedo: () -> Void
    let actionLayers: () -> Void
    let actionBgColor: (Color) -> Void
    let onDone: () -> Void
    let actionEditText: () -> Void
    let actionCopy: () -> Void
    let actionDelete: () -> Void
    let actionUp: (CGFloat,CGFloat) -> Void
    let actionDown: (CGFloat,CGFloat) -> Void
    let actionLeft: (CGFloat,CGFloat) -> Void
    let actionRight: (CGFloat,CGFloat) -> Void
    let actionFont: (String) -> Void
    let actionBold: () -> Void
    let actionUnderline: () -> Void
    let actionItalic: () -> Void
    let actionCapital: () -> Void
    let actionSmall: () -> Void
    let actionColor: (Color) -> Void
    let actionShadowColor: (Color) -> Void
    let getScale: () -> CGFloat
    let setScale: (CGFloat) -> Void
    let getRotation: () -> CGFloat
    let setRotation: (CGFloat) -> Void
    let getOpacity: () -> CGFloat
    let setOpacity: (CGFloat) -> Void
    let getSpace: () -> CGFloat
    let setSpace: (CGFloat) -> Void
    let actionShadowDisplay: (Bool) -> Void
    let getX: () -> CGFloat
    let setX: (CGFloat) -> Void
    let getY: () -> CGFloat
    let setY: (CGFloat) -> Void
    let getBlur: () -> CGFloat
    let setBlur: (CGFloat) -> Void
    
    @State var bgColor: Color = Color.white
    var body:some View{
        
        VStack(spacing: 0){
            
            HStack{
                
                Image("layers_icon")
        
                    .resizable()
                    .scaledToFit()
                    .frame(width: 27,height: 27)
                    .onTapGesture {
                        actionLayers()
                    }
                Spacer()
                
                Image("undo_icon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 27,height: 27)
                    .foregroundStyle(
                        isUndoEmpty ? Color(hex: 0x111827).opacity(0.5) : Color(hex: 0x111827)
                    )
                    .onTapGesture {
                        actionUndo()
                    }
                
                Spacer()
                
                Image("redo_icon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 27,height: 27)
                    .foregroundStyle(
                        isRedoEmpty ? Color(hex: 0x111827).opacity(0.5) : Color(hex: 0x111827)
                    )
                    .onTapGesture {
                        actionRedo()
                    }
                
                Spacer()
                
                ColorPicker("Choose your color",selection: $bgColor)
                    .padding()
                    .foregroundStyle(.clear)
                    .frame(width: 50,height: 50)
                
                Spacer()
                
                Image("done_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 27,height: 27)
                    .onTapGesture {
                        onDone()
                    }
            }
            .padding(.horizontal)
            .onChange(of: bgColor) { oldValue, newValue in
                
                print("Color changed from \(oldValue) to \(newValue)")
                actionBgColor(newValue)
            }
            
            
            
            if controllSelected != nil{
                
                Divider()
                    .frame(height: 0.5)
                    .background(.black)
                    .padding(.top)
                
                
                ZStack{
                    
                    switch controllSelected {
                    case .controlls:
                        TextControl(
                            actionEditText: actionEditText,selectedIdKind: selectedIdKind ,actionCopy: actionCopy, actionDelete: actionDelete, actionUp: actionUp, actionDown: actionDown, actionLeft: actionLeft, actionRight: actionRight
                        )
                    case .fonts:
                        FontControl(actionFont: actionFont)
                    case .size:
                        ScaleControl(get: getScale, set: setScale)
                    case .style:
                        StyleControl(actionBold: actionBold, actionUnderline: actionUnderline, actionItalic: actionItalic, actionCapital: actionCapital, actionSmall: actionSmall)
                    case .colors:
                        ColorControl(actionColor: actionColor)
                    case .shadow:
                        ShadowControl(actionShadowDisplay: actionShadowDisplay, actionShadowColor: actionShadowColor, getX: getX, setX: setX, getY: getY, setY: setY, getBlur: getBlur, setBlur: setBlur)
                    case .opacity:
                        OpacityControl(get: getOpacity, set: setOpacity)
                    case .rotate:
                        RotationControl(get: getRotation, set: setRotation)
                    case .spacing:
                        SpacingControl(get: getSpace, set: setSpace)
                    default:
                        EmptyView()
                    }
                    
                }
                .frame(height: 180)
                .frame(maxWidth:.infinity)
            }
            
            
        }
        .padding(.vertical)
        .frame(maxWidth:.infinity)
        .background(Color(hex: 0xB8C7DA))
        .clipShape(
            RoundedRectangle(cornerRadius: 26)
        )
        .padding(.horizontal)
  
        
        
        
    }
}

struct mFooter: View {
    
    let controlSelected: Bool
    let selectedIdKind: Int
    let showFont: Bool
    let showImport: Bool
    @Binding var currentControll: ControlKind?
    let actionText: () -> Void
    let actionIcon: () -> Void
    let actionShape: () -> Void
    let actionBackground: () -> Void
    let actionImport: () -> Void
    let actionControl: () -> Void
    let actionFont: () -> Void
    let actionSize: () -> Void
    let actionTextStyle:() -> Void
    let actionTextColor: () -> Void
    let actionShadow: () -> Void
    let actionOpacity: () -> Void
    let actionRotate: () -> Void
    let actionSpacing: () -> Void
    var body: some View {
        
        ZStack{
            
            if controlSelected{
                ScrollView(.horizontal, showsIndicators: false){
                    HStack(spacing: 40){
                        
                        mControlChild(
                            image: "control_icon",
                            title: "Controls",
                            isSelected: currentControll == ControlKind.controlls,
                            action: {
                                currentControll = .controlls
                                actionControl()
                            }
                        )
                        
                        
                        if showFont{
                            if selectedIdKind != 1{
                                
                                mControlChild(
                                    image: "font_icon",
                                    title: "Fonts",
                                    isSelected: currentControll == ControlKind.fonts,
                                    action: {
                                        currentControll = .fonts
                                        actionFont()
                                    }
                                )
                                
                            }
                        }
           
               
                        
                        
                        mControlChild(
                            image: "size_icon",
                            title: "Size",
                            isSelected: currentControll == ControlKind.size,
                            action: {
                                currentControll = .size
                                actionSize()
                            }
                        )
                        
                        
                        if selectedIdKind != 1{
                            mControlChild(
                                image: "text_style_icon",
                                title: "Text Style",
                                isSelected: currentControll == ControlKind.style,
                                action: {
                                    currentControll = .style
                                    actionTextStyle()
                                }
                            )
                            
                            mControlChild(
                                image: "text_color_icon",
                                title: "Colors",
                                isSelected: currentControll == ControlKind.colors,
                                action: {
                                    currentControll = .colors
                                    actionTextColor()
                                }
                            )
                            
                            mControlChild(
                                image: "shadow_icon",
                                title: "Shadow",
                                isSelected: currentControll == ControlKind.shadow,
                                action: {
                                    currentControll = .shadow
                                    actionShadow()
                                }
                            )
                        }
            
                        
                        
                        
                        
                        mControlChild(
                            image: "opacity_icon",
                            title: "Opacity",
                            isSelected: currentControll == ControlKind.opacity,
                            action: {
                                currentControll = .opacity
                                actionOpacity()
                            }
                        )
                        
                        
                        mControlChild(
                            image: "rotate_icon",
                            title: "Rotate",
                            isSelected: currentControll == ControlKind.rotate,
                            action: {
                                currentControll = .rotate
                                actionRotate()
                            }
                        )
                        
                        
                        if selectedIdKind != 1{
                            mControlChild(
                                image: "spacing_icon",
                                title: "Spacing",
                                isSelected: currentControll == ControlKind.spacing,
                                action: {
                                    currentControll = .spacing
                                    actionSpacing()
                                }
                            )
                        }
               
                        
                        
                    }
                }
            }else{
                
                HStack{
                    
                    mFooterChild(
                        image: "text_add_icon", title: "Add Text", action: actionText
                    )
                    Spacer()
                    mFooterChild(
                        image: "add_icon", title: "Icon", action: actionIcon
                    )
                    Spacer()
                    mFooterChild(
                        image: "add_shapes", title: "Shapes", action: actionShape
                    )
                    Spacer()
                    
                    if showImport{
                        mFooterChild(
                            image: "add_bg", title: "Import", action: actionImport
                        )
                    }else{
                        mFooterChild(
                            image: "add_bg", title: "Background", action: actionBackground
                        )
                    }
                
                    
                }
            }
            
            
            
            
        }
        .padding(.horizontal)
        .padding(.vertical)
        .frame(maxWidth:.infinity)
        .background(Color(hex: 0xB8C7DA))
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 26,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 26
        ))
        
        
        
    }
}

struct mFooterChild:View {
    
    let image: String
    let title: String
    let action: () -> Void
    var body: some View {
        VStack{
            
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 25,height: 25)
            
            
            Text(title)
                .foregroundStyle(Color(hex:  0x111827))
                .font(.footnote)
                .fontWeight(.semibold)
        }
        .onTapGesture {
            action()
        }
    }
}

struct mControlChild:View {
    
    let image: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        VStack{
            
            Image(image)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 25,height: 25)
                .foregroundStyle(
                    isSelected ?
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
            
            
            Text(title)
                .foregroundStyle(Color(hex:  0x111827))
                .font(.footnote)
                .fontWeight(.semibold)
        }
        .onTapGesture {
            action()
        }
    }
}

struct ShadowControl: View {
    
    
    let actionShadowDisplay: (Bool) -> Void
    let actionShadowColor: (Color) -> Void
    let getX: () -> CGFloat
    let setX: (CGFloat) -> Void
    let getY: () -> CGFloat
    let setY: (CGFloat) -> Void
    let getBlur: () -> CGFloat
    let setBlur: (CGFloat) -> Void
    
    @State private var selectedColor: Color = .red
    @State private var shadowKind = ShadowKind.off
    @State private var selected: ShadowKind = .off
    
    var body: some View {
        
        VStack{
            
            Spacer()
            
            
            if shadowKind == .angle {
                VStack(alignment:.center){
                    
                    HStack{
                        
                        Text("X")
                            .foregroundStyle(Color(hex: 0x111827))
                        
                        Slider(
                            value: Binding(
                                get: { getX() },
                                set: { v in
                                    setX(v)
                                }
                            ),
                            in: 0.0...10.0
                        )
                        .accentColor(Color(hex: 0x111827))
                        .padding(.horizontal)
                    }
                    
                    
                    HStack{
                        
                        Text("Y")
                            .foregroundStyle(Color(hex: 0x111827))
                        
                        Slider(
                            value: Binding(
                                get: { getY() },
                                set: { v in
                                    setY(v)
                                }
                            ),
                            in: 0.0...10.0
                        )
                        .accentColor(Color(hex: 0x111827))
                        .padding(.horizontal)
                    }
                    
                }
            }
            
            if shadowKind == .blur {
                
                
                VStack{
                    
                    Slider(
                        value: Binding(
                            get: { getBlur() },
                            set: { v in
                                setBlur(v)
                            }
                        ),
                        in: 0.0...3.0
                    )
                    .accentColor(Color(hex: 0x111827))
                    .padding(.horizontal)
                }
            }
            
            if shadowKind == .color{
                
                VStack{
                    
                    HStack{
                        
                        ColorPicker("Choose your color",selection: $selectedColor)
                            .padding()
                            .foregroundStyle(.white)
                            .frame(width: 50,height: 50)
                        
                        
                        Spacer()
                        
                        
                        Rectangle()
                            .fill(Color(hex: 0xFFFFFF))
                            .frame(width: 50,height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                actionShadowColor(Color(hex: 0xFFFFFF))
                            }
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(Color(hex: 0xC95858))
                            .frame(width: 50,height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                actionShadowColor(Color(hex: 0xC95858))
                            }
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(Color(hex: 0x2C309D))
                            .frame(width: 50,height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                actionShadowColor(Color(hex: 0x2C309D))
                            }
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(Color(hex: 0xC01BAA))
                            .frame(width: 50,height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                actionShadowColor(Color(hex: 0xC01BAA))
                            }
                        
                        
                    }
                    .onChange(of: selectedColor) { oldValue, newValue in
                        
                        print("Color changed from \(oldValue) to \(newValue)")
                        actionShadowColor(newValue)
                    }
                    
                    
                    HStack{
                        
                        
                        Rectangle()
                            .fill(Color(hex: 0x34B8FF))
                            .frame(width: 50,height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                actionShadowColor(Color(hex: 0x34B8FF))
                            }
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(Color(hex: 0x31D166))
                            .frame(width: 50,height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                actionShadowColor(Color(hex: 0x31D166))
                            }
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(Color(hex: 0xC3903E))
                            .frame(width: 50,height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                actionShadowColor(Color(hex: 0xC3903E))
                            }
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(Color(hex: 0x111827))
                            .frame(width: 50,height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                actionShadowColor(Color(hex: 0x111827))
                            }
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(Color(hex: 0x212121))
                            .frame(width: 50,height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                actionShadowColor(Color(hex: 0x212121))
                            }
                        
                        
                        
                    }
                    
                }
                
            }
            
            Spacer()
            
            
            HStack{
                
                
                Text("Off")
                    .foregroundStyle(
                        selected == .off ?
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
                    .fontWeight(.semibold)
                    .onTapGesture {
                        shadowKind = .off
                        selected = .off
                        actionShadowDisplay(false)
                    }
                
                
                Spacer()
                
                
                Text("Angle")
                    .foregroundStyle(
                        selected == .angle ?
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
                    .fontWeight(.semibold)
                    .onTapGesture {
                        shadowKind = .angle
                        selected = .angle
                        actionShadowDisplay(true)
                    }
                
                Spacer()
                
                Text("Blur")
                    .foregroundStyle(
                        selected == .blur ?
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
                    .fontWeight(.semibold)
                    .onTapGesture {
                        shadowKind = .blur
                        selected = .blur
                        actionShadowDisplay(true)
                    }
                
                Spacer()
                
                
                Text("Color")
                    .foregroundStyle(
                        selected == .color ?
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
                    .fontWeight(.semibold)
                    .onTapGesture {
                        shadowKind = .color
                        selected = .color
                        actionShadowDisplay(true)
                    }
                
            }
            
            
            
            
            
            
            
            
            
            
        }
        .padding()
        .frame(maxWidth:.infinity)
    }
}

struct ColorControl: View {
    
    let actionColor: (Color) -> Void
    @State private var selectedColor: Color = .red
    var body: some View {
        VStack(spacing: 20){
            
            
            HStack{
                
                ColorPicker("Choose your color",selection: $selectedColor)
                    .padding()
                    .foregroundStyle(.white)
                    .frame(width: 50,height: 50)
                
                
                Spacer()
                
                
                Rectangle()
                    .fill(Color(hex: 0xFFFFFF))
                    .frame(width: 50,height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        actionColor(Color(hex: 0xFFFFFF))
                    }
                
                Spacer()
                
                Rectangle()
                    .fill(Color(hex: 0xC95858))
                    .frame(width: 50,height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        actionColor(Color(hex: 0xC95858))
                    }
                
                Spacer()
                
                Rectangle()
                    .fill(Color(hex: 0x2C309D))
                    .frame(width: 50,height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        actionColor(Color(hex: 0x2C309D))
                    }
                
                Spacer()
                
                Rectangle()
                    .fill(Color(hex: 0xC01BAA))
                    .frame(width: 50,height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        actionColor(Color(hex: 0xC01BAA))
                    }
                
                
            }
            
            
            HStack{
                
                
                Rectangle()
                    .fill(Color(hex: 0x34B8FF))
                    .frame(width: 50,height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        actionColor(Color(hex: 0x34B8FF))
                    }
                
                Spacer()
                
                Rectangle()
                    .fill(Color(hex: 0x31D166))
                    .frame(width: 50,height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        actionColor(Color(hex: 0x31D166))
                    }
                
                Spacer()
                
                Rectangle()
                    .fill(Color(hex: 0xC3903E))
                    .frame(width: 50,height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        actionColor(Color(hex: 0xC3903E))
                    }
                
                Spacer()
                
                Rectangle()
                    .fill(Color(hex: 0x111827))
                    .frame(width: 50,height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        actionColor(Color(hex: 0x111827))
                    }
                
                Spacer()
                
                Rectangle()
                    .fill(Color(hex: 0x212121))
                    .frame(width: 50,height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        actionColor(Color(hex: 0x212121))
                    }
                
                
                
            }
            
            
            
            
        }
        .padding()
        .frame(maxWidth:.infinity)
        .onChange(of: selectedColor) { oldValue, newValue in
            
            print("Color changed from \(oldValue) to \(newValue)")
            actionColor(newValue)
        }
    }
}

struct StyleControl: View{
    
    let actionBold: () -> Void
    let actionUnderline: () -> Void
    let actionItalic: () -> Void
    let actionCapital: () -> Void
    let actionSmall: () -> Void
    var body: some View{
        
        
        HStack{
            
            Image("bold_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 27,height: 27)
                .onTapGesture {
                    actionBold()
                }
            Spacer()
            
            Image("underline_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 27,height: 27)
                .onTapGesture {
                    actionUnderline()
                }
            
            Spacer()
            
            Image("italic_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 27,height: 27)
                .onTapGesture {
                    actionItalic()
                }
            
            Spacer()
            
            Image("capital_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 27,height: 27)
                .onTapGesture {
                    actionCapital()
                }
            
            Spacer()
            
            Image("small_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 27,height: 27)
                .onTapGesture {
                    actionSmall()
                }
        }
        .padding(.horizontal,30)
        
        
    }
}

struct SpacingControl: View {
    
    let get: () -> CGFloat
    let set: (CGFloat) -> Void
    
    var body: some View {
        VStack{
            
            Slider(
                value: Binding(
                    get: { get() },
                    set: { v in
                        set(v)
                    }
                ),
                in: 0...50
            )
            .accentColor(Color(hex: 0x111827))
            
            
            HStack{
                Text("Less")
                    .foregroundStyle(.black)
                    .font(.footnote)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("More")
                    .foregroundStyle(.black)
                    .font(.footnote)
                    .fontWeight(.semibold)
            }
            
        }
        .padding(.horizontal)
        .frame(maxWidth:.infinity)
    }
}

struct OpacityControl: View{
    
    let get: () -> CGFloat
    let set: (CGFloat) -> Void
    var body: some View{
        
        ZStack(alignment:.center){
            
     

            
            Slider(
                value: Binding(
                    get: { get() },
                    set: { v in
                        set(v)
                    }
                ),
                in: 0...255
            )
            .accentColor(Color(hex: 0x111827))
            .padding(.horizontal)
            
        }
        .frame(maxWidth:.infinity)
    }
}

struct RotationControl: View{
    
    let get: () -> CGFloat
    let set: (CGFloat) -> Void
    
    var body: some View{
        
        ZStack(alignment:.center){
            
            Slider(
                value: Binding(
                    get: { get() },
                    set: { v in
                        set(v)
                    }
                ),
                in: -180...180
            )
            .accentColor(Color(hex: 0x111827))
            .padding(.horizontal)
            
        }
        .frame(maxWidth:.infinity)
    }
}

struct ScaleControl: View{
    
    let get: () -> CGFloat
    let set: (CGFloat) -> Void
    var body: some View{
        
        ZStack(alignment:.center){
            
            Slider(
                value: Binding(
                    get: { get() },
                    set: { v in
                        set(max(0.25, min(4, v)))
                    }
                ),
                in: 0.25...4.0
            )
            .accentColor(Color(hex: 0x111827))
            .padding(.horizontal)
            
        }
        .frame(maxWidth:.infinity)
    }
}

struct FontControl:View{
    
    let fonts = [
        "Poppins","FiraSans","Lora","Montserrat","Nunito"
    ]
    let actionFont: (String) -> Void
    
    var body: some View{
        
        ZStack(alignment: .center){
            
            ScrollView(.horizontal, showsIndicators: false){
                
                LazyHStack{
                    
                    ForEach(fonts,id: \.self){ font in
                        
                        if font.isEmpty{
                            Text("Invitation")
                                .foregroundStyle(Color(hex: 0x111827))
                                .font(.system(size: 24))
                                .onTapGesture {
                                    actionFont(font)
                                }
                        }else{
                            Text("Invitation")
                                .foregroundStyle(Color(hex: 0x111827))
                                .font(.custom(font, size: 24))
                                .onTapGesture {
                                    actionFont(font)
                                }
                        }
                  
                    }
                    
                }
                .padding(.leading,150)
                .padding(.trailing)
                
            }
            
            
            
        }
        
        .frame(maxWidth:.infinity)
        
        
    }
    
    
}

struct TextControl: View {
    
    let actionEditText: () -> Void
    let selectedIdKind: Int
    let actionCopy: () -> Void
    let actionDelete: () -> Void
    let actionUp: (CGFloat,CGFloat) -> Void
    let actionDown: (CGFloat,CGFloat) -> Void
    let actionLeft: (CGFloat,CGFloat) -> Void
    let actionRight: (CGFloat,CGFloat) -> Void
    
    let step:CGFloat = 5
    
    
    var body: some View {
        HStack{
            
            VStack{
                
                Spacer()
                
                if selectedIdKind != 1{
                    
                    Text("Edit Text")
                        .foregroundStyle(.white)
                        .padding(.vertical,10)
                        .padding(.horizontal,22)
                        .background(Color(hex: 0x111827))
                        .clipShape(.capsule)
                        .onTapGesture {
                            actionEditText()
                        }
                    
                    Spacer(minLength: 10)
                }
       
                
                HStack(spacing: 60){
                    
                    Image("copy_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25,height: 25)
                        .onTapGesture {
                            actionCopy()
                        }
                    
                    
                    
                    Image("delete_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25,height: 25)
                        .onTapGesture {
                            actionDelete()
                        }
                    
                }
                
                Spacer()
                
            }
            .padding(.leading)
            
            Spacer()
            
            
            VStack(spacing: 16) {
                
                
                RepeatButton(action: {actionUp(0, -step)}, label: {
                    Image("up_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40,height: 40)
                
                })
          
                
                HStack(spacing: 65) {
                    
                    RepeatButton(action: {actionUp(-step, 0)}, label: {
                        Image("left_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40,height: 40)
                    })
                    
                    RepeatButton(action: {actionUp(step, 0)}, label: {
                        Image("right_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40,height: 40)
                    })
                    
                }
                
                RepeatButton(action: {actionUp(0, step)}, label: {
                    Image("down_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40,height: 40)
                   
                
                })
           
            }
            .padding(.trailing)
            .padding(.top)
            
            
            
            
            
        }
        .padding(.vertical)
        .padding(.horizontal)
        .frame(maxWidth:.infinity)
    }
}

struct LayerInvitationPanelView: View {
    
    @Binding var layers: [InvitationLayer]
    
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


#Preview {
    CreateInvitation()
}


enum ShadowKind {
    case off
    case angle
    case blur
    case color
}

enum ControlKind{
    case controlls
    case fonts
    case size
    case style
    case colors
    case shadow
    case opacity
    case rotate
    case spacing
}

struct InvitationLayer: Identifiable{
    enum Kind { case image(src: UIImage?), text(TextProps) }
    
    struct TextProps {
        
        var text: String
        var color: Color? = nil
        var font: String? = nil
        var bold: Bool = false
        var underline: Bool = false
        var italic: Bool = false
        var capital: Bool = false
        var small: Bool = false
        var letterSpacing: Float = 0
        var shadow: Bool = false
        var shadowX: CGFloat = 0
        var shadowY: CGFloat = 0
        var shadowBlur: CGFloat = 3.0
        var shadowColor: Color? = nil
        var space: CGFloat = 0
        
        
    }
    
    let id: UUID
    var name: String
    var kind: Kind
    
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    var rotation: CGFloat   // degrees
    var scale: CGFloat
    var opacity: CGFloat = 255
    
    
    func deepCopy() -> InvitationLayer {
    
           return InvitationLayer(
               id: UUID(),
               name: self.name,
               kind: copyKind(self.kind),
               x: self.x,
               y: self.y,
               width: self.width,
               height: self.height,
               rotation: self.rotation,
               scale: self.scale
           )
       }

       private func copyKind(_ kind: Kind) -> Kind {
           switch kind {
           case .image(let src):
               return .image(src: src?.copy() as? UIImage)
           case .text(let props):
               return .text(props) // struct copy is fine
           }
       }
    
    
}


struct ViewCapture<Content: View>: UIViewRepresentable {
    
    // 1. The SwiftUI content passed to the capturer.
    var content: Content
    
    // 2. The callback closure executed when the image capture is complete.
    var onCapture: (UIImage?) -> Void
    
    // MARK: - UIViewRepresentable Methods

    func makeUIView(context: Context) -> UIView {
        // Create a UIHostingController to host the SwiftUI content.
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        
        // Use a container view to manage the layout.
        let container = UIView()
        container.addSubview(hostingController.view)
        
        // Set up constraints to make the hosting controller's view fill the container.
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: container.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        // Force the layout pass to ensure the view has the correct final size
        // before we try to render it.
        container.setNeedsLayout()
        container.layoutIfNeeded()
        
        // Perform the capture asynchronously on the main thread after layout.
        DispatchQueue.main.async {
            self.capture(view: hostingController.view)
        }
        
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // This method is not needed for a one-time snapshot operation.
    }
    
    // MARK: - Core Image Rendering

    private func capture(view: UIView) {
        // Create a renderer matching the final size of the view.
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        
        let image = renderer.image { _ in
            // Draw the view's hierarchy (including all subviews) into the context.
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        
        // Call the completion handler.
        onCapture(image)
    }
}

extension View {
    func captureView(onCapture: @escaping (UIImage?) -> Void) -> some View {
        ViewCapture(content: self, onCapture: onCapture)
    }
}
