//
//  RemoteConfigManager.swift
//  Ai Image Art
//
//  Created by Apple on 18/10/2025.
//


import Foundation
import FirebaseRemoteConfig

@MainActor
final class RemoteConfigManager: ObservableObject {
    static let shared = RemoteConfigManager()

    private let rc: RemoteConfig
    private var realtimeHandle: ConfigUpdateListenerRegistration?

    // MARK: - Init

    private init() {
        rc = RemoteConfig.remoteConfig()

        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0        // fast iteration in debug
        #else
        settings.minimumFetchInterval = 60 * 60  // 1 hour in prod (tune as needed)
        #endif
        rc.configSettings = settings

        // Load defaults from a plist if present (optional)
        if let url = Bundle.main.url(forResource: "RemoteConfigDefaults", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
            rc.setDefaults(dict as? [String: NSObject])
        }
    }

    // MARK: - Public API

    /// Fetches latest values and activates them. Notifies listeners via `objectWillChange`.
    func fetchAndActivate() async {
        do {
            // You can pass expirationDuration to honor cache; 0 forces a network fetch.
            _ = try await rc.fetch(withExpirationDuration: 0)
            _ = try await rc.activate()
            objectWillChange.send()
        } catch {
            print("RemoteConfig fetch/activate failed:", error.localizedDescription)
        }
    }

    /// Start Realtime Remote Config updates. Call once (e.g., on app start).
    func startRealtimeUpdates() {
        guard realtimeHandle == nil else { return }

        realtimeHandle = rc.addOnConfigUpdateListener { [weak self] update, error in
            guard let self else { return }
            if let error { print("RC realtime update error:", error.localizedDescription); return }
            guard let update else { return }
            // You can inspect updated keys if you need to react to specific ones:
            // print("Updated keys:", update.updatedKeys)

            self.rc.activate { _, error in
                if let error { print("RC activate after realtime update failed:", error.localizedDescription) }
                Task { @MainActor in self.objectWillChange.send() }
            }
        }
    }

    /// Stop realtime updates (e.g., on sign out or app background if you want).
    func stopRealtimeUpdates() {
        realtimeHandle?.remove()
        realtimeHandle = nil
    }

    // MARK: - Typed getters

    func string(_ key: String, default defaultValue: String = "") -> String {
        rc.configValue(forKey: key).stringValue
    }

    func bool(_ key: String, default defaultValue: Bool = false) -> Bool {
        // `boolValue` already provides a sensible default (false)
        rc.configValue(forKey: key).boolValue
    }

    func int(_ key: String, default defaultValue: Int = 0) -> Int {
        rc.configValue(forKey: key).numberValue.intValue
    }

    func double(_ key: String, default defaultValue: Double = 0) -> Double {
        rc.configValue(forKey: key).numberValue.doubleValue
    }

    /// Decode a JSON blob at `key` into `Decodable` (e.g., AB test payloads).
    func decode<T: Decodable>(_ type: T.Type, forKey key: String, default defaultValue: T) -> T {
        let data = rc.configValue(forKey: key).dataValue
        if data.isEmpty{
            return defaultValue
        }
        return (try? JSONDecoder().decode(T.self, from: data)) ?? defaultValue
    }

    // MARK: - Defaults (programmatic, optional)

    /// Set defaults from a dictionary (e.g., for unit tests or dynamic bootstrapping).
    func setDefaults(_ dict: [String: NSObject]) {
        rc.setDefaults(dict)
    }
}
