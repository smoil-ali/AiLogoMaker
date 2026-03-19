//
//  TemplateEditorView.swift
//  InvitationMaker
//
//  Created by Apple on 09/11/2025.
//


import SwiftUI
import CoreGraphics
import Photos
import ImageIO
import MobileCoreServices
import UIKit

// MARK: - Public entry

public struct TemplateEditorView: View {
    public enum ScaleMode { case aspectFit, aspectFill, stretch }
    
    let template: TemplateDocument
    let scaleMode: ScaleMode = .aspectFit
    
    // Editable layer state (canvas units)
    @EnvironmentObject var route: NavigationRouter
    @Environment(\.dismiss) var dismiss
    @State private var layers: [EditableLayer] = []
    @State private var initialLayers: [EditableLayer] = []
    @State private var selectedID: UUID? = nil
    @State private var selectedTab: Tab? = nil
    
    @State private var undoStack: [[EditableLayer]] = []
    @State private var redoStack: [[EditableLayer]] = []
    
    @State private var changeSessionActive: Bool = false
    @State private var changeSessionTimer: Timer? = nil
    @State private var showLayerPanel = false
  
    
    @State private var showSaveAlert = false
    @State private var saveResult = false
    @State private var message = ""
    private let changeSessionIdle: TimeInterval = 0.35
    @State private var currentTextAnimation: FooterAnim = .BounceIn
    @State private var layerAnimations: [UUID: LayerAnimState] = [:]
    @State private var showCommentDialog: Bool = false
    
    @State private var watermarkEnabled: Bool = true
    @State private var watermarkImageName: String = "watermark_icon" // asset name in bundle
    @State private var watermarkOpacity: CGFloat = 0.85
    // Size of watermark (in canvas units). For example 80 means 80x80 points on the canvas.
    @State private var watermarkSizeInCanvas: CGFloat = 80
    // padding from bottom-right edge in canvas units
    @State private var watermarkPaddingInCanvas: CGFloat = 12
    

    
    
//    public init(template: TemplateDocument, scaleMode: ScaleMode = .aspectFit) {
//        self.template = template
//        self.scaleMode = scaleMode
//    }
    
    public var body: some View {
        VStack(spacing: 0) {
            
            TopBar(onBack:{dismiss()},onLayer: {
                showLayerPanel = true
            }, onUndo: {
                if !undoStack.isEmpty{
                    undo()
                }
            }, onReset: {
                reset()
            }, onRedo: {
                if !redoStack.isEmpty{
                    redo()
                }
            },
            onGif: {
                selectedTab = .GifMode
            }
            ,onSave: {
                showSaveAlert = true
            })
            .sheet(isPresented: $showLayerPanel) {
                LayerPanelView(layers: $layers, onMove: { from, to in
                    // push a snapshot for undo BEFORE making the move
                    pushState(action: "reorder")
                    // perform the move
                    layers.move(fromOffsets: from, toOffset: to)
                    // clear redo stack because new action occurred
                    redoStack.removeAll()
                })
                .presentationDetents([.medium, .large])
            }
            
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
                            LayerRender(layer: layer, animState: layerAnimations[layer.id])
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
                .frame(width: layout.contentSize.width, height: layout.contentSize.height)
                .overlay(
                    Group {
                        if watermarkEnabled, let wm = loadWatermarkImage(named: watermarkImageName) {
                            
                            
                            ZStack{
                                
                                GIFWebView(gifName: "watermark_gif")
                                    .aspectRatio(contentMode: .fit)
                                    
                            }
                            .frame(width: watermarkSizeInCanvas * layout.scale,
                                   height: watermarkSizeInCanvas * layout.scale)
                            .padding(.bottom, watermarkPaddingInCanvas * layout.scale)
                            .padding(.trailing, watermarkPaddingInCanvas * layout.scale)
                            .onTapGesture{
                    
                            }
//                            Image(uiImage: wm)
//                                .resizable()

                         
                        }
                    },
                    alignment: .bottomTrailing
                )
                .position(x: geo.size.width/2, y: geo.size.height/2)
                .background(Color.black.opacity(0.02))
                .onAppear {
                    if layers.isEmpty {
                        layers = EditableLayer.from(template: template)
                        
                        initialLayers = layers.map { $0 }
                        
                        undoStack.removeAll()
                        redoStack.removeAll()
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
                                    
                           
                                    switch l?.kind{
                                        
                                    case .image(_):
                                        selectedTab = .AddImage
                                    case .text(_):
                                        print("here")
                                        selectedTab = .AddText
                                    default:
                                        selectedTab = nil
                                        
                                    }
                                    
                                } else {
                                    selectedTab = nil
                                    selectedID = nil
                                }
                        }
                )
                
        
                
            }
            
            Divider()
            
            ControllerBar(selected: Binding(
                get: {layers.first(where: {$0.id == selectedID })},
                set: { updated in
                    guard let updated else { return }
                    if let idx = layers.firstIndex(where: {$0.id == updated.id}){
                        
                        beginAtomicChange(action: "edit")
                        layers[idx] = updated
                        
                        scheduleEndAtomicChange()
                    }
                    
                }
            ),selectedTab: $selectedTab,
                          beginScaling: {
                beginAtomicChange(action: "scale")
            },
                          endScaling: {
                scheduleEndAtomicChange()
            },
                          beginRotation: {
                beginAtomicChange(action: "Rotation")
            },
                          endRotation: {
                scheduleEndAtomicChange()
            },
                          onTextChanges: {
//                pushState(action: "textChange")
            },
            onNudge: {dx,dy in
                
                guard let id = selectedID, let idx = layers.firstIndex(where: { $0.id == id }) else { return }
                beginAtomicChange(action: "translate")
                layers[idx].x += dx
                layers[idx].y += dy
                scheduleEndAtomicChange()
                
                
            },onBounceIn: {
                
                print("bounc in animation")
                animateAll(.BounceIn)
                
            },onFadeIn: {
                animateAll(.FadeIn)
            },onZoomIn: {
                animateAll(.ZoomIn)
            },
            onDelete: { layer in
                
               
                pushState(action: "delete")
                if let index = layers.firstIndex(where: { $0.id == layer.id }) {
                    
                    print("before size \(layers.count)")
                    layers.remove(at: index)
                    print("after size \(layers.count)")
                    
                }
            },onChangeText: {showCommentDialog = true},
                          onCancel: {
                selectedTab = nil
                selectedID = nil
            }
            )
            .background(.ultraThinMaterial)
         
            
        }
        .CommentDialog(isPresented: $showCommentDialog, inputText: currentText(), onDone: { text in
            
            
            showCommentDialog = false
            var item = layers.first(where: {$0.id == selectedID })
            
            if var s = item,
               case .text(var textProperty) = s.kind
            {
                // mutate the local copy
                textProperty.text = text
                s.kind = .text(textProperty)
                
                if let rect = getTextWidth(input: text, layer: s){
                    
                    s.width = rect.width
                    s.height = rect.height
                    
                    item = s
                    
                    guard let item else { return }
                    
                    if let idx = layers.firstIndex(where: {$0.id == item.id}){
                        
                        beginAtomicChange(action: "edit")
                        layers[idx] = item
                        
                        scheduleEndAtomicChange()
                    }
                }
            
       
       

       
    
            }
            
            
        }, onCancel: {
            showCommentDialog = false
        })
        .saveDialog(isPresented: $showSaveAlert, onImage: {
            
            saveAsImage()
            showSaveAlert = false
        }, onGif: {
            
            saveAsGif()
            showSaveAlert = false
            
        }, onCancel: {
            showSaveAlert = false
        })
        .alert("Alert", isPresented: $saveResult, actions: {
            Button("Ok", action: {
                saveResult = false
            })
        }, message: {
            Text(message)
        })
        .background(.white)
        .ignoresSafeArea(.keyboard)
        
    }
    
    private func getTextWidth(input: String,layer: EditableLayer)-> CGRect?{
        switch layer.kind {
        case .text(let props):
            
            let uiColor = UIColor(red: CGFloat(props.color.r), green: CGFloat(props.color.g), blue: CGFloat(props.color.b), alpha: CGFloat(props.color.a))
            
            let font: UIFont = {
                let cleanedFamily = props.fontFamily.replacingOccurrences(of: " ", with: "")
                _ = props.fontWeight.replacingOccurrences(of: " ", with: "")

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
            
            print("k 14")

            paragraph.lineBreakMode = .byWordWrapping
            paragraph.lineSpacing = 0

            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: uiColor,
                .paragraphStyle: paragraph
            ]
            
            let ns = NSString(string: props.text)
            let textSize = ns.size(withAttributes: attrs)
            let textRect = CGRect(origin: .zero, size: textSize)
            
         
            return textRect
           
        default:
            return nil
            
        }
    }
    
    private func currentText() -> String{
        guard let item = layers.first(where: {$0.id == selectedID }) else {return ""}
        
        switch item.kind {
        case .text(let prop):
            return prop.text
        default:
            return ""
        }
    }
    
    private func saveAsGif() {
        
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
                            watermarkOpacity: 0.85
                            ) { result in
              switch result {
              case .success(let fileURL):
                  // Optionally save to Photos
                  saveGIFToPhotos(fileURL: fileURL) { result in
                      switch result {
                      case .success():
                          print("GIF saved to Photos")
                          message = "GIF saved to Photos!"
                          saveResult = true

                      case .failure(let err):
                          print("Failed to save GIF to Photos:", err)
                          message = "GIF Failed to save to Photos"
                          saveResult = true

                      }
                  }
              case .failure(let err):
                  print("Failed to render GIF:", err)
                  message = "GIF Failed to save to Photos"
                  saveResult = true

              }
          }
    }
    
    private func saveAsImage() {
        let canvasSize = CGSize(width: template.canvas.width, height: template.canvas.height)
        

        // choose scale = 1 (exact canvas pixels) or UIScreen.main.scale for retina.
        let rendered = renderCanvasImage(templateSize: canvasSize, layers: layers, scale: UIScreen.main.scale)
        
        saveImageToPhotos(rendered) { result in
            switch result {
            case .success:
                // show confirmation UI — e.g. toast or alert
                print("Saved to Photos")
                message = "Image saved to photos"
                saveResult = true
            case .failure(let error):
                print("Failed to save: \(error.localizedDescription)")
                message = "Image failed to save"
                saveResult = true
            }
        }
        
        print("4")
    }
    
    /// Animate all text layers with a chosen preset, with simple staggering.
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
                    withAnimation(.interpolatingSpring(stiffness: 180, damping: 18).delay(baseDuration)) {
                        layerAnimations[id]?.scale = 1.0
                        layerAnimations[id]?.offset = .zero
                    }
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

    
    private func map(_ mode: ScaleMode) -> TemplateView.ScaleMode {
        switch mode { case .aspectFit: .aspectFit; case .aspectFill: .aspectFill; case .stretch: .stretch }
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
        // add to history record list
//        let rec = HistoryRecord(date: Date(), action: action, snapshot: layers.map{ $0 })
//        historyRecords.insert(rec, at: 0)
//        // Keep history short (optional)
//        if historyRecords.count > 100 { historyRecords.removeLast() }
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
    
    private func reset() {
        // restore initial layers
        layers = initialLayers.map { $0 }
        // clear selection and UI state
        selectedID = nil
        selectedTab = nil
        // clear undo/redo/history
        undoStack.removeAll()
        redoStack.removeAll()
//        historyRecords.removeAll()
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
                name.draw(in: drawRect)
            } else {
                // fallback: draw placeholder rect
                gc.setFillColor(UIColor(white: 0.9, alpha: 1).cgColor)
                
                gc.fill(drawRect)
            }

        case .text(let props):
            // Build attributes: color + font
            
            print("k 11")
            let uiColor = UIColor(red: CGFloat(props.color.r), green: CGFloat(props.color.g), blue: CGFloat(props.color.b), alpha: CGFloat(props.color.a))
            // Try font by exact asset name "Family-Weight" or family only; fallback to system
    
            print("k 12")
            
    
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

            paragraph.lineBreakMode = .byWordWrapping
            paragraph.lineSpacing = 0

            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: uiColor,
                .paragraphStyle: paragraph
            ]
            
            print("k 15")

            let ns = NSString(string: props.text)
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

}




// MARK: - Editable model

struct EditableLayer: Identifiable {
    enum Kind { case image(src: UIImage?), text(TextProps) }
    struct TextProps {
        var color: ColorValue
        var fontSize: CGFloat
        var fontFamily: String
        var fontWeight: String
        var hAlign: HorizontalAlign
        var vAlign: VerticalAlign
        var text: String
        
        var kolor: Color? = nil
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
    
    // Geometry in canvas units
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    var rotation: CGFloat   // degrees
    var scale: CGFloat
    var opacity: CGFloat = 255// 1 = original
    
    static func from(template: TemplateDocument) -> [EditableLayer] {
        var out: [EditableLayer] = []
        // Images
        for img in template.images {
            out.append(.init(
                id: UUID(),
                name: img.name,
                kind: .image(src: img.uiImage),
                x: img.x, y: img.y, width: img.width, height: img.height,
                rotation: img.rotation, scale: 1
            ))
        }
        // Texts
        for t in template.texts {
            out.append(.init(
                id: UUID(),
                name: t.name,
                kind: .text(.init(
                    color: t.color,
                    fontSize: t.fontSize,
                    fontFamily: t.fontFamily,
                    fontWeight: t.fontWeight,
                    hAlign: t.horizontalAlignment,
                    vAlign: t.verticalAlignment,
                    text: t.text ?? ""
                )),
                x: t.x, y: t.y, width: t.width, height: t.height,
                rotation: t.rotation, scale: 1
            ))
        }
        
      
        return out
    }
    
    func deepCopy() -> EditableLayer {
    
           return EditableLayer(
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

// MARK: - Renderers

fileprivate struct LayerRender: View {
    let layer: EditableLayer
    let animState: LayerAnimState?

    init(layer: EditableLayer, animState: LayerAnimState? = nil) {
        self.layer = layer
        self.animState = animState
    }

    
    var body: some View {
        switch layer.kind {
        case .image(let src):
            LayerImageView(imageName: src)
                .clipped()
        case .text(let p):
            LayerTextView(
                text: p.text,
                color: p.color.swiftUIColor,
                fontSize: p.fontSize,
                fontFamily: p.fontFamily,
                weight: p.fontWeight,
                hAlign: p.hAlign,
                vAlign: p.vAlign
            )
            .opacity(animState?.opacity ?? 1.0)
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

// MARK: - Control bar

fileprivate struct ControlBar: View {
    @Binding var selected: EditableLayer?
    let nudge: (CGFloat, CGFloat) -> Void
    let bringToFront: () -> Void
    let sendToBack: () -> Void
    
    // Nudge step in canvas units
    let step: CGFloat = 5
    
    var body: some View {
        VStack(spacing: 10) {

            
            HStack(spacing: 18) {
                // Arrow pad
                VStack(spacing: 8) {
                    
                    RepeatButton(action: {nudge(0, -step)}, label: {
                        Image(systemName: "arrow.up")
                    })
                 
                    HStack(spacing: 24) {
                        RepeatButton(action: {nudge(-step, 0)}, label:{
                            Image(systemName: "arrow.left")
                        })
                               
                        RepeatButton(action: {nudge(step, 0) }, label: {
                            Image(systemName: "arrow.right")
                        })
                    }
                    RepeatButton(action: {nudge(0, step) }, label: {
                            Image(systemName: "arrow.down")
                    })
                }
                .buttonStyle(.bordered)
                
                Divider().frame(height: 72)
                
                // Scale slider
                VStack(alignment: .leading) {
                    HStack {
                        Text("Scale")
                        Spacer()
                        Text(String(format: "%.2fx", selected?.scale ?? 1))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { selected?.scale ?? 1 },
                            set: { v in
                                guard var s = selected else { return }
                                s.scale = max(0.25, min(4, v))
                                selected = s
                            }
                        ),
                        in: 0.25...4.0
                    )
                }
                
                // Rotation slider
                VStack(alignment: .leading) {
                    HStack {
                        Text("Rotation")
                        Spacer()
                        Text("\(Int(selected?.rotation ?? 0))°")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { selected?.rotation ?? 0 },
                            set: { v in
                                guard var s = selected else { return }
                                s.rotation = v
                                selected = s
                            }
                        ),
                        in: -180...180
                    )
                }
            }
        }
        .disabled(selected == nil)
        .opacity(selected == nil ? 0.6 : 1)
    }
}





struct RepeatButton<Label: View>: View {
    var interval: TimeInterval = 0.05        // repeat speed
    var longPressDelay: TimeInterval = 0.25  // hold time before repeating
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var timer: Timer?
    @State private var pendingWork: DispatchWorkItem?

    var body: some View {
        label()
            .contentShape(Rectangle())

            // 1) Single tap => one action
            .simultaneousGesture(
                TapGesture()
                    .onEnded { action() }
            )

            // 2) Press & hold lifecycle (down/up), reliable across iOS versions
            .onLongPressGesture(minimumDuration: 0, maximumDistance: 20,
                                pressing: { isDown in
                if isDown {
                    // schedule start after longPressDelay
                    scheduleStart()
                } else {
                    // finger lifted/cancelled
                    cancelStart()
                    stopTimer()
                }
            }, perform: {
                // no-op: we handle repeating ourselves
            })
            .onDisappear {
                cancelStart()
                stopTimer()
            }
    }

    private func scheduleStart() {
        // already queued or running? ignore
        if pendingWork != nil || timer != nil { return }
        let work = DispatchWorkItem {
            startTimer()
        }
        pendingWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + longPressDelay, execute: work)
    }

    private func cancelStart() {
        pendingWork?.cancel()
        pendingWork = nil
    }

    private func startTimer() {
        cancelStart()
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            action()
        }
        if let t = timer {
            RunLoop.current.add(t, forMode: .common)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
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

// === Reuse your previous helpers ===

// LayerImageView / LayerTextView from earlier answer:
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
    let fontSize: CGFloat
    let fontFamily: String
    let weight: String
    let hAlign: HorizontalAlign
    let vAlign: VerticalAlign


    
    var body: some View {
        
        let alignment = Alignment(horizontal: hAlign.swiftUI, vertical: vAlign.swiftUI)
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
            Text(text)
                .foregroundColor(color)
                .font(.custom(fontFamily, size: fontSize))
                .multilineTextAlignment(multiline)
                .lineLimit(nil)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: Alignment(horizontal: hAlign.swiftUI, vertical: vAlign.swiftUI))
     
            
       
            
        }
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

fileprivate extension CGAffineTransform {
    func invertedOrIdentity() -> CGAffineTransform {
        guard let inv = self.inverted() as CGAffineTransform? else { return .identity }
        return inv
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

fileprivate func easeOutCubic(_ t: Double) -> Double {
    let p = t - 1
    return 1 + p * p * p
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
                let outURL = tempDir.appendingPathComponent("template_export_\(Int(Date().timeIntervalSince1970)).gif")
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


extension Color {
    func toRGB() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        let uiColor = UIColor(self)

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (r, g, b, a)
        }
        return nil
    }
}

extension EditableLayer {

    @ViewBuilder
    var icon: some View {
        switch kind {
        case .image(let src):
            if let name = src {
                Image(uiImage: name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
            } else {
                // fallback if missing
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
                    .frame(width: 30, height: 30)
            }

        case .text(let t):
            ZStack {
                Color.purple.opacity(0.2)
                Text(t.text.prefix(2).uppercased())   // EX: "He" for "Hello"
                    .font(.headline)
                    .foregroundColor(.purple)
            }
            .frame(width: 40, height: 40)
            .cornerRadius(4)
        }
    }
}


struct LayerPanelView: View {
    
    @Binding var layers: [EditableLayer]
    
    var onMove: ((_ from: IndexSet, _ to: Int) -> Void)? = nil

    var body: some View {
        List {
            ForEach(layers) { layer in
                HStack {
                    layer.icon

                    VStack(alignment: .leading) {
                        Text(layer.name).font(.headline)

                        switch layer.kind {
                        case .image:
                            Text("Image").font(.caption).foregroundColor(.secondary)
                        case .text(let text):
                            Text("Text: \"\(text.text)\"")
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


