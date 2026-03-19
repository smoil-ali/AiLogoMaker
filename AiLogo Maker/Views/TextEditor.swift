import SwiftUI
import Photos
import PhotosUI
import CoreGraphics






// MARK: - Text Editor View
struct TextEditorView: View {
    @State private var originalImage: UIImage? = nil
    @State private var showingPicker = false
    @State private var exportAlert: (title: String, message: String)? = nil

    // Fit mapping
    @State private var lastFitRect: CGRect = .zero
    @State private var lastScale: CGFloat = 1
    @State private var containerSize: CGSize = .zero

    // Text overlay state
    @State private var overlayText: String = ""
    @State private var isEditingText: Bool = true
    @State private var textPosition: CGPoint? = nil
    @State private var textFontSize: CGFloat = 36
    @State private var textBold: Bool = true
    @State private var textColor: Color = .black

    // Pinch-zoom on TEXT only
    @State private var textScale: CGFloat = 1
    @State private var baseTextScale: CGFloat = 1

    // Pinch-zoom state (two-finger gesture)
    @State private var zoomScale: CGFloat = 1
    @State private var baseZoom: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack {
                GeometryReader { geo in
                    if let img = originalImage {
                        let fit = aspectFitRect(container: geo.size, image: img.size)
                        Color.clear
                            .onAppear { storeFit(fit: fit, container: geo.size) }
                            .onChange(of: geo.size) { newSize in
                                let newFit = aspectFitRect(container: newSize, image: img.size)
                                storeFit(fit: newFit, container: newSize)
                            }

                        // Zoomable content
                        ZStack {
                            Image(uiImage: img)
                                .resizable()
                                .interpolation(.high)
                                .antialiased(true)
                                .frame(width: fit.rect.width, height: fit.rect.height)
                                .position(x: fit.rect.midX, y: fit.rect.midY)

                            if !overlayText.isEmpty, let pos = textPosition {
                                Text(overlayText)
                                    .font(.system(size: textFontSize, weight: textBold ? .bold : .regular))
                                    .foregroundStyle(textColor)
                                    .scaleEffect(textScale, anchor: .center)
                                    .position(pos)
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                let p = value.location
                                                let clamped = CGPoint(x: min(max(p.x, fit.rect.minX), fit.rect.maxX),
                                                                      y: min(max(p.y, fit.rect.minY), fit.rect.maxY))
                                                self.textPosition = clamped
                                            }
                                    )
                                    .onAppear {
                                        if textPosition == nil {
                                            textPosition = CGPoint(x: fit.rect.midX, y: fit.rect.midY)
                                        }
                                    }
                            }
                        }

                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 56))
                            Text("Pick an image to start")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            toolbar
        }
        .sheet(isPresented: $showingPicker) {
            ImagePicker { img in
                self.originalImage = img
                self.overlayText = ""
                self.textPosition = nil
            }
        }
        .alert(item: Binding(get: {
            exportAlert.map { AlertItem(id: UUID(), title: $0.title, message: $0.message) }
        }, set: { _ in exportAlert = nil })) { item in
            Alert(title: Text(item.title), message: Text(item.message), dismissButton: .default(Text("OK")))
        }
    }

    var header: some View {
        HStack(spacing: 12) {
            Button { showingPicker = true } label: {
                Label("Pick Image", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.bordered)

            Divider().frame(height: 24)

            HStack(spacing: 8) {
                TextField("Enter text…", text: $overlayText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 180)
                    .onSubmit {
                        if lastFitRect != .zero { textPosition = CGPoint(x: lastFitRect.midX, y: lastFitRect.midY) }
                        isEditingText = false
                    }
                Button("Place Center") {
                    if lastFitRect != .zero { textPosition = CGPoint(x: lastFitRect.midX, y: lastFitRect.midY) }
                    isEditingText = false
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Text("Size")
                Slider(value: $textFontSize, in: 10...128, step: 1)
                    .frame(width: 180)
                Text("\(Int(textFontSize))")
                    .monospacedDigit()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    var toolbar: some View {
        HStack {
            Spacer()
            Button {
                saveToPhotos()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(originalImage == nil || overlayText.isEmpty || textPosition == nil)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func storeFit(fit: (rect: CGRect, scale: CGFloat), container: CGSize) {
        self.lastFitRect = fit.rect
        self.lastScale = fit.scale
        self.containerSize = container
        if textPosition == nil && !overlayText.isEmpty {
            textPosition = CGPoint(x: fit.rect.midX, y: fit.rect.midY)
        }
    }

    private func saveToPhotos() {
        guard let base = originalImage?.normalizedOrientation(),
              lastFitRect != .zero,
              let pos = textPosition,
              !overlayText.isEmpty else {
            exportAlert = ("Error", "Nothing to save.")
            return
        }

        let fitRect = lastFitRect
        let scale = lastScale
        let mappedCenter = viewPointToImagePoint(pos, imageFitRect: fitRect, scale: scale)
        let mappedFontSize = (textFontSize * textScale) / scale

        let out = renderTextOnOriginal(baseImage: base,
                                       text: overlayText,
                                       center: mappedCenter,
                                       fontSize: mappedFontSize,
                                       color: UIColor(textColor))

        requestPhotoAccessIfNeeded { granted in
            guard granted else {
                exportAlert = ("Permission Needed", "Please allow Photos access to save the image.")
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: out)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        exportAlert = ("Saved", "Edited image saved to Photos.")
                    } else {
                        exportAlert = ("Save Failed", error?.localizedDescription ?? "Unknown error")
                    }
                }
            }
        }
    }

    private func renderTextOnOriginal(baseImage: UIImage,
                                      text: String,
                                      center: CGPoint,
                                      fontSize: CGFloat,
                                      color: UIColor) -> UIImage {
        let size = baseImage.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = baseImage.scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            baseImage.draw(in: CGRect(origin: .zero, size: size))
            let font = UIFont.systemFont(ofSize: fontSize, weight: textBold ? .bold : .regular)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color
            ]
            let textSize = (text as NSString).size(withAttributes: attrs)
            let origin = CGPoint(x: center.x - textSize.width/2, y: center.y - textSize.height/2)
            (text as NSString).draw(at: origin, withAttributes: attrs)
        }
    }

    private func requestPhotoAccessIfNeeded(_ cb: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited: cb(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { s in
                DispatchQueue.main.async { cb(s == .authorized || s == .limited) }
            }
        default: cb(false)
        }
    }
}

private struct AlertItem: Identifiable { let id: UUID; let title: String; let message: String }


