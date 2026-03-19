//
//  FileUtils.swift
//  InvitationMaker
//
//  Created by Apple on 15/12/2025.
//

import Foundation
import UIKit
import Photos


final class FileUtils {

    static let shared = FileUtils()
    private init() {}

    // MARK: - Directories

    private func tempDirectory() -> URL {
        FileManager.default.temporaryDirectory
    }

    private func savedImagesDirectory() -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Saved Images")

        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(
                at: dir,
                withIntermediateDirectories: true
            )
        }
        return dir
    }

    // MARK: - Create Files

    func createTempFile(image: UIImage) -> URL {
        let fileURL = tempDirectory()
            .appendingPathComponent("temp_\(UUID().uuidString).png")

        if let data = image.pngData() {
            try? data.write(to: fileURL, options: .atomic)
        }
        return fileURL
    }

    func createFileWithJpeg(image: UIImage) -> URL {
        let fileURL = savedImagesDirectory()
            .appendingPathComponent("img_\(UUID().uuidString).jpg")

        if let data = image.jpegData(compressionQuality: 0.9) {
            try? data.write(to: fileURL, options: .atomic)
        }
        return fileURL
    }

    func createFileWidthPng(image: UIImage) -> URL {
        let fileURL = savedImagesDirectory()
            .appendingPathComponent("img_\(UUID().uuidString).png")

        if let data = image.pngData() {
            try? data.write(to: fileURL, options: .atomic)
        }
        return fileURL
    }
    
    
    func createFileWithPdf(image: UIImage) -> URL {
           let url = savedImagesDirectory()
               .appendingPathComponent("img_\(UUID().uuidString).pdf")

           let pageRect = CGRect(origin: .zero, size: image.size)

           let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

           do {
               try renderer.writePDF(to: url) { context in
                   context.beginPage()
                   image.draw(in: pageRect)
               }
           } catch {
               print("PDF creation failed:", error)
           }

           return url
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

    // MARK: - Read

    func getAllSavedImages() -> [URL] {
        let dir = savedImagesDirectory()
        return (try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        )) ?? []
    }
}



final class FileViewModel: ObservableObject {

    @Published var savedFiles: [URL] = []

    private let utils = FileUtils.shared

    // MARK: - Read

    func getAllSavedFiles() -> [URL] {
        let files = utils.getAllSavedImages()
            .sorted { $0.lastPathComponent > $1.lastPathComponent }

        DispatchQueue.main.async {
            self.savedFiles = files
        }
        return files
    }

    // MARK: - Create

    func createTempFile(image: UIImage) -> URL {
        return utils.createTempFile(image: image)
    }

    func createFileWithJpeg(image: UIImage) {
        utils.createFileWithJpeg(image: image)
        getAllSavedFiles()
    }
    
    func createFileWithPdf(image: UIImage) {
        utils.createFileWithPdf(image: image)
        getAllSavedFiles()
    }

    func createFileWidthPng(image: UIImage) {
        utils.createFileWidthPng(image: image)
        getAllSavedFiles()
    }
    
    func saveImageToGallery(image: UIImage,completion: @escaping (Result<Void, Error>) -> Void) {
        utils.saveImageToPhotos(image,completion: completion)
    }
    

     func shareImage(from url: URL) {
         guard let image = UIImage(contentsOfFile: url.path) else { return }
         ShareUtils.shareImage(image)
     }

     func shareImage(_ image: UIImage) {
         ShareUtils.shareImage(image)
     }
}


final class ShareUtils {

    static func shareImage(_ image: UIImage) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // iPad fix (required)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(
                x: rootVC.view.bounds.midX,
                y: rootVC.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        rootVC.present(activityVC, animated: true)
    }
    
    static func sharePDF(_ pdfURL: URL) {
            guard FileManager.default.fileExists(atPath: pdfURL.path) else {
                print("PDF file not found")
                return
            }

            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = scene.windows.first?.rootViewController else {
                return
            }

            let activityVC = UIActivityViewController(
                activityItems: [pdfURL],   // 🔥 PDF stays PDF
                applicationActivities: nil
            )

            // Required for iPad (prevents crash)
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(
                    x: rootVC.view.bounds.midX,
                    y: rootVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }

            rootVC.present(activityVC, animated: true)
        }
}



