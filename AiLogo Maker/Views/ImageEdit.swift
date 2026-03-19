import SwiftUI
import Photos
import PhotosUI
import CoreGraphics

// MARK: - Models
struct Stroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var lineWidth: CGFloat
}

// MARK: - Utilities
extension UIImage {
    /// Returns a new UIImage in .up orientation to avoid coordinate surprises
    func normalizedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img ?? self
    }
}

/// Compute the aspectFit rect of an image inside a container, centered.
func aspectFitRect(container: CGSize, image: CGSize) -> (rect: CGRect, scale: CGFloat) {
    guard image.width > 0, image.height > 0 else { return (.zero, 1) }
    let sx = container.width / image.width
    let sy = container.height / image.height
    let scale = min(sx, sy)
    let w = image.width * scale
    let h = image.height * scale
    let x = (container.width - w) / 2
    let y = (container.height - h) / 2
    return (CGRect(x: x, y: y, width: w, height: h), scale)
}

/// Map a point from view-space to original-image pixel space, given the fitted rect and scale.
func viewPointToImagePoint(_ p: CGPoint, imageFitRect: CGRect, scale: CGFloat) -> CGPoint {
    let x = (p.x - imageFitRect.minX) / scale
    let y = (p.y - imageFitRect.minY) / scale
    return CGPoint(x: x, y: y)
}

// MARK: - Image Picker (PHPicker)
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onPick: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            defer { parent.dismiss() }
            guard let provider = results.first?.itemProvider else { return }
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { obj, _ in
                    if let img = obj as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.onPick(img.normalizedOrientation())
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Editor View
struct ImageEditorView: View {
    @State private var originalImage: UIImage? = nil
    @State private var strokes: [Stroke] = []
    @State private var currentStroke: Stroke? = nil
    @State private var showingPicker = false
    @State private var exportAlert: (title: String, message: String)? = nil

    // Keep exact geometry used during drawing so export maps 1:1
    @State private var lastFitRect: CGRect = .zero
    @State private var lastScale: CGFloat = 1
    @State private var containerSize: CGSize = .zero

    // Drawing config
    @State private var strokeWidth: CGFloat = 6

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack {
                GeometryReader { geo in
                    if let img = originalImage {
                        // Compute fit rect
                        let fit = aspectFitRect(container: geo.size, image: img.size)
                        // Attach the side-effect to a view modifier so it conforms to ViewBuilder
                        // Store mapping on appear and whenever geometry changes
                        Color.clear
                            .onAppear { storeFit(fit: fit, container: geo.size) }
                            .onChange(of: geo.size) { newSize in
                                let newFit = aspectFitRect(container: newSize, image: img.size)
                                storeFit(fit: newFit, container: newSize)
                            }
                        // Base image
                        Image(uiImage: img)
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                            .frame(width: fit.rect.width, height: fit.rect.height)
                            .position(x: fit.rect.midX, y: fit.rect.midY)

                        // Existing strokes (in view space)
                        ForEach(strokes) { stroke in
                            Path { path in
                                guard let first = stroke.points.first else { return }
                                path.move(to: first)
                                for p in stroke.points.dropFirst() { path.addLine(to: p) }
                            }
                            .stroke(Color.black, lineWidth: stroke.lineWidth)
                            .drawingGroup()
                        }

                        // Current stroke preview
                        if let s = currentStroke {
                            Path { path in
                                guard let first = s.points.first else { return }
                                path.move(to: first)
                                for p in s.points.dropFirst() { path.addLine(to: p) }
                            }
                            .stroke(Color.black, lineWidth: s.lineWidth)
                            .drawingGroup()
                        }

                        // Touch layer to collect points only inside the image rect
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    var pt = value.location
                                    // Clamp to the image rect so we don't draw outside
                                    if !fit.rect.contains(pt) { return }
                                    if currentStroke == nil {
                                        currentStroke = Stroke(points: [pt], lineWidth: strokeWidth)
                                    } else {
                                        currentStroke?.points.append(pt)
                                    }
                                }
                                .onEnded { _ in
                                    if let s = currentStroke { strokes.append(s) }
                                    currentStroke = nil
                                }
                            )
                    } else {
                        // Placeholder
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
                self.strokes.removeAll()
            }
        }
        .alert(item: Binding(get: {
            exportAlert.map { AlertItem(id: UUID(), title: $0.title, message: $0.message) }
        }, set: { _ in exportAlert = nil })) { item in
            Alert(title: Text(item.title), message: Text(item.message), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - UI Pieces
    var header: some View {
        HStack {
            Button {
                showingPicker = true
            } label: {
                Label("Pick Image", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.bordered)

            Spacer()

            HStack(spacing: 12) {
                Text("Width")
                Slider(value: $strokeWidth, in: 1...24, step: 1) {
                    Text("Width")
                }
                .frame(width: 180)
                Text("\(Int(strokeWidth))")
                    .monospacedDigit()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    var toolbar: some View {
        HStack {
            Button(role: .destructive) {
                strokes.removeAll()
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .disabled(strokes.isEmpty && currentStroke == nil)

            Spacer()

            Button {
                saveToPhotos()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(originalImage == nil)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // Helper to store mapping
    private func storeFit(fit: (rect: CGRect, scale: CGFloat), container: CGSize) {
        self.lastFitRect = fit.rect
        self.lastScale = fit.scale
        self.containerSize = container
    }

    // MARK: - Export logic
    private func saveToPhotos() {
        guard let base = originalImage?.normalizedOrientation() else { return }

        // We need the *same* fitted rect & scale that were used during drawing
        guard lastFitRect != .zero, let base = originalImage?.normalizedOrientation() else {
            exportAlert = ("Error", "No image or mapping info available.")
            return
        }

        let fitRect = lastFitRect
        let scale = lastScale

        // Map all strokes from view-space -> image pixel space
        let mappedStrokes: [Stroke] = strokes.map { s in
            let mappedPoints = s.points.map { viewPointToImagePoint($0, imageFitRect: fitRect, scale: scale) }
            let mappedWidth = s.lineWidth / scale
            return Stroke(points: mappedPoints, lineWidth: mappedWidth)
        }

        // Composite onto original image size
        let out = renderOnOriginal(baseImage: base, strokes: mappedStrokes)

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

//        let (fitRect, scale) = aspectFitRect(container: rootSize, image: base.size)

        // Map all strokes from view-space -> image pixel space
//        let mappedStrokes1: [Stroke] = strokes.map { s in
//            let mappedPoints = s.points.map { viewPointToImagePoint($0, imageFitRect: fitRect, scale: scale) }
//            let mappedWidth = s.lineWidth / scale
//            return Stroke(points: mappedPoints, lineWidth: mappedWidth)
//        }
//
//        // Composite onto original image size
//        let out1 = renderOnOriginal(baseImage: base, strokes: mappedStrokes1)

//        requestPhotoAccessIfNeeded { granted in
//            guard granted else {
//                exportAlert = ("Permission Needed", "Please allow Photos access to save the image.")
//                return
//            }
//            PHPhotoLibrary.shared().performChanges {
//                PHAssetChangeRequest.creationRequestForAsset(from: out1)
//            } completionHandler: { success, error in
//                DispatchQueue.main.async {
//                    if success {
//                        exportAlert = ("Saved", "Edited image saved to Photos.")
//                    } else {
//                        exportAlert = ("Save Failed", error?.localizedDescription ?? "Unknown error")
//                    }
//                }
//            }
//        }
    }

    private func renderOnOriginal(baseImage: UIImage, strokes: [Stroke]) -> UIImage {
        let size = baseImage.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = baseImage.scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            // Draw original
            baseImage.draw(in: CGRect(origin: .zero, size: size))
            // Draw strokes in image pixel space
            UIColor.black.setStroke()
            for s in strokes {
                guard let first = s.points.first else { continue }
                let path = UIBezierPath()
                path.move(to: first)
                for p in s.points.dropFirst() { path.addLine(to: p) }
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.lineWidth = s.lineWidth
                path.stroke()
            }
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



// MARK: - Helpers
private extension UIWindowScene {
    var keyWindow: UIWindow? { self.windows.first { $0.isKeyWindow } }
}
