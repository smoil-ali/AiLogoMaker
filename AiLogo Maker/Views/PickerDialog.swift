//
//  PickerDialog.swift
//  Ai Image Art
//
//  Created by Apple on 23/09/2025.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

struct PickerDialog: ViewModifier {
    @Binding var isPresented: Bool
     var onPicked: (URL) -> Void
     var onCancel: (() -> Void)? = nil

     @State private var showCamera = false
     @State private var showGallery = false
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog("Select Image", isPresented: $isPresented, titleVisibility: .visible) {
                Button("Camera")  { showCamera  = true }
                Button("Gallery") { showGallery = true }
                Button("Cancel", role: .cancel) { onCancel?() }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { url in onPicked(url) }
            }
            .sheet(isPresented: $showGallery) {
                GalleryPicker { url in onPicked(url) }
            }
    }
}

extension View {
    /// Presents a dialog with Camera/Gallery and returns a local file URL of the chosen image.
    func imageSourceDialog(isPresented: Binding<Bool>,
                           onPicked: @escaping (URL) -> Void,
                           onCancel: (() -> Void)? = nil) -> some View {
        modifier(PickerDialog(isPresented: isPresented, onPicked: onPicked, onCancel: onCancel))
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    var onPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onPicked: (URL) -> Void
        init(onPicked: @escaping (URL) -> Void) { self.onPicked = onPicked }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Prefer original image
            let image = (info[.originalImage] ?? info[.editedImage]) as? UIImage
            guard let image, let data = image.jpegData(compressionQuality: 0.95) else {
                picker.dismiss(animated: true); return
            }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("camera_\(UUID().uuidString).jpg")
            do {
                try data.write(to: url, options: .atomic)
                DispatchQueue.main.async { self.onPicked(url) }
            } catch {
                // ignore error, just close
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct GalleryPicker: UIViewControllerRepresentable {
    var onPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let onPicked: (URL) -> Void
        init(onPicked: @escaping (URL) -> Void) { self.onPicked = onPicked }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let item = results.first?.itemProvider else {
                picker.dismiss(animated: true); return
            }

            // Prefer file representation (keeps original format/metadata if possible)
            if item.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                item.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { srcURL, _ in
                    defer { DispatchQueue.main.async { picker.dismiss(animated: true) } }
                    guard let srcURL else { return }
                    let ext = (srcURL.pathExtension.isEmpty ? "img" : srcURL.pathExtension)
                    let dest = FileManager.default.temporaryDirectory
                        .appendingPathComponent("gallery_\(UUID().uuidString).\(ext)")
                    do {
                        // Copy to our sandbox (srcURL may be ephemeral)
                        if FileManager.default.fileExists(atPath: dest.path) {
                            try? FileManager.default.removeItem(at: dest)
                        }
                        try FileManager.default.copyItem(at: srcURL, to: dest)
                        DispatchQueue.main.async { self.onPicked(dest) }
                    } catch {
                        // Fallback: load as UIImage then write JPEG
                        self.fallbackLoadAsImage(item, picker: picker)
                    }
                }
            } else {
                fallbackLoadAsImage(item, picker: picker)
            }
        }

        private func fallbackLoadAsImage(_ item: NSItemProvider, picker: PHPickerViewController) {
            if item.canLoadObject(ofClass: UIImage.self) {
                item.loadObject(ofClass: UIImage.self) { obj, _ in
                    defer { DispatchQueue.main.async { picker.dismiss(animated: true) } }
                    guard let img = obj as? UIImage, let data = img.jpegData(compressionQuality: 0.95) else { return }
                    let dest = FileManager.default.temporaryDirectory
                        .appendingPathComponent("gallery_\(UUID().uuidString).jpg")
                    try? data.write(to: dest, options: .atomic)
                    DispatchQueue.main.async { self.onPicked(dest) }
                }
            } else {
                DispatchQueue.main.async { picker.dismiss(animated: true) }
            }
        }
    }
}


