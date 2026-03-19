//
//  TemplateView.swift
//  InvitationMaker
//
//  Created by Apple on 09/11/2025.
//


import SwiftUI
import CoreGraphics

// MARK: - Public entry point

public struct TemplateView: View {
    public enum ScaleMode { case aspectFit, aspectFill, stretch }
    
    let template: TemplateDocument
    let scaleMode: ScaleMode = .aspectFit
//    
//    public init(template: TemplateDocument) {
//        self.template = template
//        self.scaleMode = scaleMode
//    }
    
    public var body: some View {
        GeometryReader { geo in
            let layout = LayoutMapper(
                canvas: CGSize(width: template.canvas.width, height: template.canvas.height),
                container: geo.size,
                mode: scaleMode
            )
            
            ZStack(alignment: .topLeading) {
                // Images
                ForEach(Array(template.images.enumerated()), id: \.offset) { _, img in
                    let rect = layout.mapRect(x: img.x, y: img.y, w: img.width, h: img.height)
                    LayerImageView(imageName: img.src ?? img.name)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .rotationEffect(.degrees(Double(img.rotation)), anchor: .center)
                }
                
                // Texts
                ForEach(Array(template.texts.enumerated()), id: \.offset) { _, t in
                    let rect = layout.mapRect(x: t.x, y: t.y, w: t.width, h: t.height)
                    LayerTextView(text: t.text ?? "",
                                  color: t.color.swiftUIColor,
                                  fontSize: layout.mapScalar(t.fontSize),
                                  fontFamily: t.fontFamily,
                                  weight: t.fontWeight,
                                  hAlign: t.horizontalAlignment,
                                  vAlign: t.verticalAlignment)
                        .frame(width: rect.width, height: rect.height, alignment: .center)
                        .position(x: rect.midX, y: rect.midY)
                        .rotationEffect(.degrees(Double(t.rotation)), anchor: .center)
                        .accessibilityLabel(Text(t.name))
                }
            }
            // Letterbox centering
            .frame(width: layout.contentSize.width, height: layout.contentSize.height, alignment: .topLeading)
            .position(x: geo.size.width/2, y: geo.size.height/2)
            .background(Color.clear) // transparent background; add canvas fill if you want
        }
    }
}

// MARK: - Layout mapper (canvas → container)

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
            fallthrough
        default:
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
            let sx = scale, sy = scale
            return CGRect(x: x * sx, y: y * sy, width: w * sx, height: h * sy)
        }
    }
    
    /// For sizes like fontSize that live in canvas units
    func mapScalar(_ v: CGFloat) -> CGFloat {
        switch mode {
        case .stretch:
            // Use average to keep font scale sane when non-uniform
            return v * ((scaleX + scaleY) / 2)
        case .aspectFill, .aspectFit:
            return v * scale
        }
    }
}

// MARK: - Image layer view

fileprivate struct LayerImageView: View {
    let imageName: String
    var body: some View {
        #if os(iOS)
        if let ui = UIImage(named: imageName) {
            Image(uiImage: ui).resizable().interpolation(.high).clipped()
        } else {
            // fallback (e.g., remote not bundled yet)
            Color.clear.overlay(
                Text("Missing: \(imageName)").font(.caption).foregroundColor(.red)
            )
        }
        #else
        if let ns = NSImage(named: imageName) {
            Image(nsImage: ns).resizable().interpolation(.high).clipped()
        } else {
            Color.clear.overlay(
                Text("Missing: \(imageName)").font(.caption).foregroundColor(.red)
            )
        }
        #endif
    }
}

// MARK: - Text layer view

fileprivate struct LayerTextView: View {
    let text: String
    let color: Color
    let fontSize: CGFloat
    let fontFamily: String
    let weight: String
    let hAlign: HorizontalAlign
    let vAlign: VerticalAlign
    
    var body: some View {
        // Horizontal alignment for Text
        let multiline: TextAlignment = {
            switch hAlign {
            case .left: return .leading
            case .center: return .center
            case .right: return .trailing
            case .justify: return .leading // SwiftUI has no full justify; could custom draw
            }
        }()
        
        // Vertical alignment via ZStack/VStack spacers
        ZStack(alignment: Alignment(horizontal: hAlign.swiftUI, vertical: vAlign.swiftUI)) {
            Text(text)
                .foregroundColor(color)
                .font(.custom(fontFamily, size: fontSize))
                .multilineTextAlignment(multiline)
                .lineLimit(nil)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: Alignment(horizontal: hAlign.swiftUI, vertical: vAlign.swiftUI))
        }
    }
}

// MARK: - Small bridges from your earlier models

extension ColorValue {
    var swiftUIColor: Color { Color(red: r, green: g, blue: b, opacity: a) }
}

extension FontWeight {
    var swiftUIFontWeight: Font.Weight {
        switch self {
        case .named(let n):
            switch n {
            case .ultraLight: return .ultraLight
            case .thin:       return .thin
            case .light:      return .light
            case .regular:    return .regular
            case .medium:     return .medium
            case .semibold:   return .semibold
            case .bold:       return .bold
            case .heavy:      return .heavy
            case .black:      return .black
            }
        case .numeric(let n):
            switch n {
            case ..<200:   return .ultraLight
            case 200..<300:return .thin
            case 300..<400:return .light
            case 400..<500:return .regular
            case 500..<600:return .medium
            case 600..<700:return .semibold
            case 700..<800:return .bold
            case 800..<900:return .heavy
            default:       return .black
            }
        }
    }
}

// Horizontal/Vertical align mapping to SwiftUI Alignment
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
