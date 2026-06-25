//
//  DiskCache.swift
//  sild
//

import Foundation

enum DiskCache {
    private static let directory: URL = {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = base.appendingPathComponent("cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    static func read<T: Decodable>(_ type: T.Type = T.self, key: String) -> T? {
        let url = directory.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("[DiskCache] failed to decode \(key): \(error)")
            return nil
        }
    }

    static func write<T: Encodable>(_ value: T, key: String) {
        let url = directory.appendingPathComponent("\(key).json")
        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[DiskCache] failed to write \(key): \(error)")
        }
    }

    static func remove(key: String) {
        let url = directory.appendingPathComponent("\(key).json")
        try? FileManager.default.removeItem(at: url)
    }
}
