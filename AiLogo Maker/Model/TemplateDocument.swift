//
//  TemplateDocument.swift
//  InvitationMaker
//
//  Created by Apple on 09/11/2025.
//


// TemplateModels.swift
import Foundation
import CoreGraphics
import UIKit

// MARK: - Normalized models your app will use

struct TemplateDocument {
    let canvas: Canvas
    let images: [ImageLayer]
    let texts: [TextLayer]

    static func fromFigmaJSON(data: Data, value: String, position: Int) throws -> TemplateDocument {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let figma = try decoder.decode(FigmaFrame.self, from: data)

        // Canvas
        let canvas = Canvas(width: CGFloat(figma.width), height: CGFloat(figma.height))

        // Gather layers
        var images: [ImageLayer] = []
        var texts: [TextLayer] = []

        // Base local folder: Documents/<value>/assets/<position>/
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let assetsBaseURL = docs
            .appendingPathComponent("v2")
            .appendingPathComponent("templates")
            .appendingPathComponent(value)
            .appendingPathComponent("assets")
//            .appendingPathComponent("\(position)")

        for child in figma.children ?? [] {

            switch child.type {

            case .rectangle, .other:
                // only process image fills
                if let imgFill = child.fills?.first(where: { $0.type == .image }) {

                    let layerName = imgFill.src?.split(separator: "/").last ?? ""
                    
                    
                    
                    

                    // Full path: Documents/<value>/assets/<position>/<child.name>.png
                    let localImageURL = assetsBaseURL
                        .appendingPathComponent("\(layerName)")
                    
                    

                    var uiImage: UIImage? = nil

                    if fm.fileExists(atPath: localImageURL.path) {
                        uiImage = UIImage(contentsOfFile: localImageURL.path)
                        
                        print("width and height \(layerName) \(uiImage?.size.width) \(uiImage?.size.height)")
                    }else{
                        print("path not exist: \(localImageURL.path)")
                    }

                    // If image is missing, still create layer but without UIImage
                    let imageLayer = ImageLayer(
                        name: "Image",
                        x: CGFloat(child.x ?? 0),
                        y: CGFloat(child.y ?? 0),
                        width: CGFloat(child.width ?? 0),
                        height: CGFloat(child.height ?? 0),
                        rotation: CGFloat(child.rotation ?? 0),
                        src: imgFill.src ?? imgFill.imageHash, // original reference
                        uiImage: uiImage                      // <-- ADDED
                    )

                    images.append(imageLayer)
                }

            case .text:
                let color = child.fills?.first(where: { $0.type == .solid })?.color?.asColorValue()
                ?? ColorValue(r: 0, g: 0, b: 0, a: 1)

                let hAlign = HorizontalAlign(rawValue: (child.textAlignHorizontal ?? "LEFT").lowercased()) ?? .left
                let vAlign = VerticalAlign(rawValue: (child.textAlignVertical ?? "TOP").lowercased()) ?? .top
                let (family, style) = (child.fontName?.family ?? "System", child.fontName?.style ?? "Regular")
                
                let fontFamily = family
                let withSpaces = fontFamily.replacingOccurrences(of: " ", with: "")
                let final = "\(withSpaces)-\(style)"

                texts.append(
                    TextLayer(
                        name: "Text",
                        x: CGFloat(child.x ?? 0),
                        y: CGFloat(child.y ?? 0),
                        width: CGFloat(child.width ?? 0),
                        height: CGFloat(child.height ?? 0),
                        rotation: CGFloat(child.rotation ?? 0),
                        color: color,
                        fontSize: CGFloat(child.fontSize ?? 14),
                        fontFamily: final,
                        fontWeight: style,
                        horizontalAlignment: hAlign,
                        verticalAlignment: vAlign,
                        text: child.characters
                    )
                )

            default:
                break
            }
        }

        return TemplateDocument(canvas: canvas, images: images, texts: texts)
    }

}

struct Canvas: Codable {
    let width: CGFloat
    let height: CGFloat
}

struct ImageLayer {
    let name: String
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let rotation: CGFloat
    let src: String?
    let uiImage: UIImage?
}

struct TextLayer: Codable {
    let name: String
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let rotation: CGFloat
    let color: ColorValue
    let fontSize: CGFloat
    let fontFamily: String
    let fontWeight: String
    let horizontalAlignment: HorizontalAlign
    let verticalAlignment: VerticalAlign
    let text: String?
}

enum HorizontalAlign: String, Codable {
    case left, center, right, justify
}

enum VerticalAlign: String, Codable {
    case top, center, bottom
}

struct ColorValue: Codable {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
    let a: CGFloat
}

enum FontWeight: Codable {
    case named(Named)
    case numeric(Int)

    enum Named: String, Codable {
        case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black
    }

    static func fromFigmaStyle(_ style: String) -> FontWeight {
        // Map common Figma styles to weights (e.g. "Regular", "SemiBold", "Bold")
        let key = style.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch key {
        case "ultralight": return .named(.ultraLight)
        case "thin": return .named(.thin)
        case "light": return .named(.light)
        case "regular": return .named(.regular)
        case "medium": return .named(.medium)
        case "semibold", "semi bold", "semi-bold": return .named(.semibold)
        case "bold": return .named(.bold)
        case "heavy": return .named(.heavy)
        case "black": return .named(.black)
        default:
            // Parse things like "W600", "600"
            if let num = Int(key.filter(\.isNumber)) {
                return .numeric(num)
            }
            return .named(.regular)
        }
    }
}

// MARK: - Raw Figma decoding models (only what we need from your sample)

private struct FigmaFrame: Codable {
    let name: String?
    let type: FNodeType
    let x: Double?
    let y: Double?
    let width: Double
    let height: Double
    let rotation: Double?
    let children: [FigmaNode]?

    enum CodingKeys: String, CodingKey {
        case name, type, x, y, width, height, rotation, children
    }
}

private struct FigmaNode: Codable {
    let name: String?
    let type: FNodeType
    let visible: Bool?
    let x: Double?
    let y: Double?
    let width: Double?
    let height: Double?
    let rotation: Double?
    let fills: [FigmaFill]?

    // Text-specific
    let characters: String?
    let fontSize: Double?
    let textAlignHorizontal: String?
    let textAlignVertical: String?
    let fontName: FigmaFontName?

    enum CodingKeys: String, CodingKey {
        case name, type, visible, x, y, width, height, rotation, fills
        case characters, fontSize, textAlignHorizontal, textAlignVertical, fontName
    }
}

private enum FNodeType: String, Codable {
    case frame = "FRAME"
    case rectangle = "RECTANGLE"
    case text = "TEXT"
    case other

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let raw = (try? c.decode(String.self)) ?? ""
        self = FNodeType(rawValue: raw) ?? .other
    }
}

private struct FigmaFill: Codable {
    let type: FFillType
    let visible: Bool?
    let opacity: Double?
    let blendMode: String?
    let color: FigmaRGB?
    // Image-specific fields:
    let src: String?
    let scaleMode: String?
    let imageHash: String?
    let imageTransform: [[Double]]?
    let scalingFactor: Double?
    let rotation: Double?
    // (filters omitted—unused for now)

    enum CodingKeys: String, CodingKey {
        case type, visible, opacity, blendMode, color, src, scaleMode, imageHash, imageTransform, scalingFactor, rotation
    }
}

private enum FFillType: String, Codable {
    case solid = "SOLID"
    case image = "IMAGE"
    case other

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let raw = (try? c.decode(String.self)) ?? ""
        self = FFillType(rawValue: raw) ?? .other
    }
}

private struct FigmaRGB: Codable {
    let r: Double
    let g: Double
    let b: Double

    func asColorValue(alpha: Double = 1.0) -> ColorValue {
        ColorValue(r: CGFloat(r), g: CGFloat(g), b: CGFloat(b), a: CGFloat(alpha))
    }
}

private struct FigmaFontName: Codable {
    let family: String?
    let style: String?
}

// MARK: - Helpers

private extension FigmaRGB {
    func asColorValue() -> ColorValue {
        // Figmas r,g,b are already 0–1 in your sample
        ColorValue(r: CGFloat(r), g: CGFloat(g), b: CGFloat(b), a: 1)
    }
}
