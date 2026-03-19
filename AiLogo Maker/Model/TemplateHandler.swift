//
//  TemplateHandler.swift
//  InvitationMaker
//
//  Created by Apple on 09/11/2025.
//

import Foundation

@MainActor
final class TemplateHandler {
    static let shared = TemplateHandler()
    

    var template: TemplateDocument? = nil
    
    
    
    func start(value: String, position: Int) async {
        do {
            // build local file URL: Documents/<value>/jsons/<position>.json
            let fm = FileManager.default
            guard let docsURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Documents directory not found")
                return
            }

            let localURL = docsURL
                .appendingPathComponent("v2", isDirectory: true)
                .appendingPathComponent("templates", isDirectory: true)
                .appendingPathComponent(value, isDirectory: true)
                .appendingPathComponent("jsons", isDirectory: true)
                .appendingPathComponent("\(position).json", isDirectory: false)

            // check existence
            guard fm.fileExists(atPath: localURL.path) else {
                print("JSON not found at path: \(localURL.path)")
                return
            }

            // read and parse
            let data = try Data(contentsOf: localURL)
            let parsed = try TemplateDocument.fromFigmaJSON(data: data, value: value, position: position)

            // --- perform downloads & registration and WAIT for completion ---
            // Do sequential downloads and await each one.
            for text in parsed.texts {
                // honor cancellation
                try Task.checkCancellation()
                print("Downloading font:", text.fontFamily)
                do {
                    try await DataRepo.shared.downloadFonts(fontFamily: text.fontFamily)
                } catch {
                    // log and continue with next font
                    print("error \(error.localizedDescription) for \(text.fontFamily)")
                }
            }

            print("start registering...")
            // wait for registration to finish
            try await DataRepo.shared.registerAllFonts()

            // assign parsed template on main actor (UI-safe) AFTER registration completes
            await MainActor.run {
                self.template = parsed
            }

            print("here") // now this runs after downloads + registration + UI update

        } catch is CancellationError {
            print("start(...) cancelled")
        } catch {
            print("start(...) error: \(error.localizedDescription)")
        }
    }


    

    
}
