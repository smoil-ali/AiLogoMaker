//
//  DataRepo.swift
//  AiLogo Maker
//
//  Created by Apple on 26/02/2026.
//

import Foundation
import FirebaseStorage
import CoreGraphics
import UIKit

struct CategoryData: Codable,Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let total_item: Int
}

private struct TemplatesResponse: Codable {
    let allCategories: [CategoryData]
}

@MainActor
final class DataRepo: ObservableObject {
    static let shared = DataRepo()
    private init() {
        print("here in cons")
    }

    @Published private(set) var categories: [CategoryData] = []
    @Published private(set) var lastError: Error?
    @Published private(set) var isLoadingTemplates: Bool = false
    
    func initialize() async {
        
        
        print("here 1 ")
        if !isLoadingTemplates{
            print("here 2")
            isLoadingTemplates = true
            await loadTemplatesIfNeeded()
        }
   
       
    }
    
    func refresh() {
        Task {
            await refreshFromRemote()
        }
    }
    
    private func localTemplatesURL() throws -> URL {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw URLError(.fileDoesNotExist)
        }
        return docs.appendingPathComponent("logo_templates.json")
    }

    private func setCategories(_ cats: [CategoryData]) async {
        self.categories = cats
        self.lastError = nil
    }
    
    private func setError(_ error: Error) {
        self.lastError = error
    }
    
    func loadTemplatesIfNeeded() async {
        do {
            let localURL = try localTemplatesURL()
            if FileManager.default.fileExists(atPath: localURL.path) {
                print("already downloaded")
                try await parseLocalFile(at: localURL)
            } else {
                print("downloading...")
                try await downloadTemplatesToLocal(url: localURL)
                try await parseLocalFile(at: localURL)
            }
        } catch {
            setError(error)
            print("DataRepo.loadTemplatesIfNeeded error:", error)
        }
    }
    
    private func refreshFromRemote() async {
        do {
            let localURL = try localTemplatesURL()
            try await downloadTemplatesToLocal(url: localURL)
            try await parseLocalFile(at: localURL)
        } catch {
            setError(error)
            print("DataRepo.refreshFromRemote error:", error)
        }
    }
    
    private func parseLocalFile(at url: URL) async throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        // Note: your JSON has a root { "data": [...] } so decode TemplatesResponse
        let decoded = try decoder.decode(TemplatesResponse.self, from: data)
        await setCategories(decoded.allCategories)
    }
    
    private func downloadTemplatesToLocal(url localURL: URL) async throws {
        // adjust the path if your file is in a subfolder of your storage bucket
        let storageRef = Storage.storage().reference().child("logo_templates.json")

        // If file may be larger than this, increase maxSize or use write(toFile:) API.
        let maxSize: Int64 = 5 * 1024 * 1024

        let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            storageRef.getData(maxSize: maxSize) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NSError(domain: "DataRepo", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data returned from Storage."]))
                }
            }
        }

        // Ensure directory exists (usually does) and write atomically
        let fm = FileManager.default
        let dir = localURL.deletingLastPathComponent()
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        try data.write(to: localURL, options: .atomic)
    }
    
    func thumbnailURL(for value: String, position: Int) async throws -> URL {
        let path = "v2/templates/\(value)/thumbnails/\(position).png"
        let ref = Storage.storage().reference().child(path)

        return try await withCheckedThrowingContinuation { continuation in
            ref.downloadURL { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: URLError(.badURL))
                }
            }
        }
    }
}

@MainActor
extension DataRepo {
    
    func downloadAssetsOfTemplate(value: String, position: Int) async throws {
        // storage path to the "data" folder
        
        print("here 1")
        let storagePath = "v2/templates/\(value)/assets/"
        let rootRef = Storage.storage().reference().child(storagePath)

        // 1) list all files (recursively)
        let allFiles = try await listAllFilesRecursively(at: rootRef)
        
        print("here 2 \(allFiles)")

        // 2) get local documents base url
        let fm = FileManager.default
        guard let docsURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw URLError(.fileDoesNotExist)
        }
        
        print("here 3")
        
        

        // 3) Download each file preserving the storage fullPath under Documents
        for fileRef in allFiles {
            // fileRef.fullPath is the path relative to bucket root, e.g. "Baby_Shower/assets/1/data/img1.png"
            let relativePath = fileRef.fullPath

            // Create destination URL: Documents/<relativePath>
            let destURL = docsURL.appendingPathComponent(relativePath)

            // Ensure destination directory exists
            let destDir = destURL.deletingLastPathComponent()
            if !fm.fileExists(atPath: destDir.path) {
                try fm.createDirectory(at: destDir, withIntermediateDirectories: true)
            }

            // If file already exists locally, skip download
            if fm.fileExists(atPath: destURL.path) {
                // optionally: you might want to verify file size / checksum and re-download if mismatched
                continue
            }
            
            

            print("download location \(destURL)")

            // Download to temporary file then move atomically (write(toFile:) writes to a local URL)
            try await writeStorageReference(fileRef, to: destURL)
        }
    }
    
    func downloadFonts(fontFamily: String) async throws {
        
        
        print("font family \(fontFamily)")
        // storage path to the "data" folder
        let storagePath = "v2/fonts/\(fontFamily).ttf"
        let rootRef = Storage.storage().reference().child(storagePath)

   

        // 2) get local documents base url
        let fm = FileManager.default
        guard let docsURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw URLError(.fileDoesNotExist)
        }

        let destURL = docsURL.appendingPathComponent(rootRef.fullPath)
        
        let destDir = destURL.deletingLastPathComponent()
        if true {
            try fm.createDirectory(at: destDir, withIntermediateDirectories: true)
        }
        
        if !fm.fileExists(atPath: destURL.path) {
            // optionally: you might want to verify file size / checksum and re-download if mismatched
      
            try await writeStorageReference(rootRef, to: destURL)
  
        }
        
        print("already exist")
        
    }
    
    func registerAllFonts() async {
        let urls = await getLocalFontURLs()
        
        print("size \(urls.count)")
        CTFontManagerRegisterFontURLs(urls as CFArray, CTFontManagerScope.process, true,nil)
    }
    
    private func getLocalFontURLs() async -> [URL] {
        let fm = FileManager.default
        
        
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        
        let fontsDir = docs
            .appendingPathComponent("v2", isDirectory: true)
            .appendingPathComponent("fonts", isDirectory: true)
            
        
        
        print("font local path \(fontsDir)")
        // If directory does not exist, return empty
        guard fm.fileExists(atPath: fontsDir.path) else {
            return []
        }
        
        do {
            // List contents
            let items = try fm.contentsOfDirectory(at: fontsDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            
            // Filter only font file types you want
            let fontFiles = items.filter { url in
                let ext = url.pathExtension.lowercased()
                return ext == "ttf" || ext == "otf" // add more if needed
            }
            
            return fontFiles
            
        } catch {
            print("⚠️ Failed to list Fonts directory:", error)
            return []
        }
    }
    
    
    func registerFont(at url: URL) async {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else {
            print("⚠️ Font file not found:", url.path)
            return
        }

        // Try to make a CGFont so we can read PostScript name and validate file
        guard let data = try? Data(contentsOf: url),
              let provider = CGDataProvider(data: data as CFData),
              let cgFont = CGFont(provider) else {
            print("⚠️ Cannot create CGFont. File may be corrupt or not a valid TTF/OTF:", url.path)
            return
        }

        let psName = (cgFont.postScriptName as String?) ?? "<unknown-postscript-name>"
        print("ℹ️ Font PostScript name discovered:", psName)

        // If UIFont can already create a font using this PostScript name, it's already available to UIKit.
        if UIFont(name: psName, size: 12) != nil {
            print("ℹ️ Font already available to UIFont:", psName)
            // still post notification so any UI can reapply the font if needed
            return
        }

        // Optional: print CTFont descriptors inside the file (helps debugging)
        if let descs = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor], !descs.isEmpty {
            print("ℹ️ Found \(descs.count) font descriptor(s) in file:")
            for (i, d) in descs.enumerated() {
                if let name = CTFontDescriptorCopyAttribute(d, kCTFontNameAttribute) {
                    print("  [\(i)] kCTFontNameAttribute:", name)
                } else {
                    print("  [\(i)] descriptor (no kCTFontNameAttribute)")
                }
            }
        } else {
            print("⚠️ No CTFont descriptors found (file may be invalid or not supported).")
        }

        // Try URL registration (recommended for downloaded fonts) with process scope
        var registerError: Unmanaged<CFError>?
        let registeredByURL = CTFontManagerRegisterFontsForURL(url as CFURL, CTFontManagerScope.process, &registerError)

        if registeredByURL {
            print("✅ CTFontManagerRegisterFontsForURL succeeded for:", url.lastPathComponent)
            // verify UIFont can create it now
            if let _ = UIFont(name: psName, size: 12) {
                print("✅ UIFont can create the font after registration:", psName)
                return
            } else {
                print("⚠️ UIFont still cannot create the font after URL registration — will try graphics-font fallback.")
            }
        } else {
            // print detailed error info
            if let err = registerError?.takeRetainedValue() {
                let ns = err as Error as NSError
                print("❌ CTFontManagerRegisterFontsForURL failed:")
                print("   localizedDescription:", ns.localizedDescription)
                print("   domain:", ns.domain, "code:", ns.code)
                print("   userInfo:", ns.userInfo)
                // common codes: 105 (registration unsuccessful), 307 (unsupportedScope)
            } else {
                print("❌ CTFontManagerRegisterFontsForURL failed: unknown error (no CFError provided).")
            }
        }

        // Fallback: register as a graphics font (from CGFont). This sometimes succeeds when URL method fails.
        var cgErr: Unmanaged<CFError>?
        let graphicsRegistered = CTFontManagerRegisterGraphicsFont(cgFont, &cgErr)
        if graphicsRegistered {
            print("✅ CTFontManagerRegisterGraphicsFont succeeded (fallback).")
            if UIFont(name: psName, size: 12) != nil {
                print("✅ UIFont can create the font after GraphicsFont registration:", psName)
                return
            } else {
                print("⚠️ UIFont still cannot create the font even after GraphicsFont registration.")
               
                return
            }
        } else {
            if let e = cgErr?.takeRetainedValue() {
                let ns = e as Error as NSError
                print("❌ CTFontManagerRegisterGraphicsFont failed:")
                print("   localizedDescription:", ns.localizedDescription)
                print("   domain:", ns.domain, "code:", ns.code)
                print("   userInfo:", ns.userInfo)
            } else {
                print("❌ CTFontManagerRegisterGraphicsFont failed: unknown error.")
            }
        }
    }
    
    func getFileSize(forPath path: String) -> Int64? {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            if let fileSize = attributes[.size] as? UInt64 {
                return Int64(fileSize)
            }
        } catch {
            print("Error getting file size for \(path): \(error)")
        }
        return nil
    }
    
    private func listAllFilesRecursively(at ref: StorageReference) async throws -> [StorageReference] {
        var collected: [StorageReference] = []

        // list this level
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageListResult, Error>) in
            ref.listAll { res, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let res = res {
                    continuation.resume(returning: res)
                } else {
                    continuation.resume(throwing: NSError(domain: "DataRepo", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown listAll result"]))
                }
            }
        }

        // append items at this level
        collected.append(contentsOf: result.items)

        // recursively list prefixes (subfolders)
        for prefix in result.prefixes {
            let subItems = try await listAllFilesRecursively(at: prefix)
            collected.append(contentsOf: subItems)
        }

        return collected
    }

    private func writeStorageReference(_ ref: StorageReference, to localURL: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            // Storage SDK writes directly to a file URL
            let _ = ref.write(toFile: localURL) { urlOrNil, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    // success (urlOrNil points to local file)
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

@MainActor
extension DataRepo {

    func downloadJsonOfTemplate(value: String, position: Int) async throws {
        // Firebase path
        let storagePath = "v2/templates/\(value)/jsons/\(position).json"
        let storageRef = Storage.storage().reference().child(storagePath)

        // Local destination
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw URLError(.fileDoesNotExist)
        }

        let localURL = docsURL.appendingPathComponent(storagePath)

        // Extract folder path
        let dir = localURL.deletingLastPathComponent()

        // Make sure directory exists
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        // ✔ Check if file already exists
        if FileManager.default.fileExists(atPath: localURL.path) {
            print("JSON already exists locally → skipping download: \(localURL.path)")
            return
        }

        // Download JSON bytes from Firebase Storage
        let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "downloadJson",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown download error"]
                    ))
                }
            }
        }

        // Save file locally
        try data.write(to: localURL, options: .atomic)

        print("JSON downloaded & stored at: \(localURL.path)")
    }
}
