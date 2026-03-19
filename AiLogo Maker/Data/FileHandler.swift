//
//  FileHandler.swift
//  InvitationMaker
//
//  Created by Apple on 13/12/2025.
//

import Foundation
import UIKit



import UIKit

import UIKit

final class FileHandler {

    static let shared = FileHandler()
    private init() {}

    // MARK: - Folder URL
    func savedImagesFolderURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Saved Images", isDirectory: true)
    }

    // MARK: - Create Folder
    func createFolderIfNeeded() {
        let folderURL = savedImagesFolderURL()
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true
            )
        }
    }

    // MARK: - Write Image
    func writeImage(_ image: UIImage) -> URL? {
        createFolderIfNeeded()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"

        let fileName = "img_\(formatter.string(from: Date())).png"
        let fileURL = savedImagesFolderURL().appendingPathComponent(fileName)

        guard let data = image.pngData() else { return nil }

        do {
            try data.write(to: fileURL, options: .atomic)
            print("image write success")
            return fileURL
        } catch {
            print("❌ Image write failed:", error)
            return nil
        }
    }

    // MARK: - Read Files
    func readAllImages() -> [URL] {
        createFolderIfNeeded()

        do {
            let list = try FileManager.default.contentsOfDirectory(
                at: savedImagesFolderURL(),
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            print("saved files \(list.count)")
            return list
        } catch {
            return []
        }
    }
}


final class SaveViewModel: ObservableObject {

    @Published var savedFiles: [URL] = []

    private let fileHandler = FileHandler.shared
    private var folderObserver: DispatchSourceFileSystemObject?

    init() {
        observeFolder()
        loadSavedFiles()
    }

    // MARK: - Create / Save Image
    func createFile(image: UIImage) {
        fileHandler.writeImage(image)
        loadSavedFiles()
    }

    // MARK: - Load Files
    func getSaveFiles() {
        loadSavedFiles()
    }

    private func loadSavedFiles() {
        DispatchQueue.main.async {
            self.savedFiles = self.fileHandler
                .readAllImages()
                .sorted { $0.lastPathComponent > $1.lastPathComponent }
        }
    }

    // MARK: - Live Observer
    private func observeFolder() {

        let folderURL = fileHandler.savedImagesFolderURL()
        let fd = open(folderURL.path, O_EVTONLY)

        guard fd != -1 else { return }

        folderObserver = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: DispatchQueue.global()
        )

        folderObserver?.setEventHandler { [weak self] in
            self?.loadSavedFiles()
        }

        folderObserver?.setCancelHandler {
            close(fd)
        }

        folderObserver?.resume()
    }
}




    
  
