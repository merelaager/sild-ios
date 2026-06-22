//
//  ShiftRecord.swift
//  sild
//

import Foundation

struct ShiftRecord: Codable, Identifiable, Equatable {
    let id: Int
    let childId: Int
    let childName: String
    var teamId: Int?
    var teamName: String?
    var tentNr: Int?
    var isPresent: Bool
    let ageAtCamp: Int
    let year: Int
    let shiftNr: Int
}

private struct ShiftRecordsPayload: Decodable {
    let records: [ShiftRecord]
}

struct RecordSection: Identifiable {
    let id: String
    let title: String
    let records: [ShiftRecord]
}

extension Array where Element == ShiftRecord {
    func groupedByTent() -> [RecordSection] {
        let groups = Dictionary(grouping: self, by: \.tentNr)
        let numbered = groups
            .compactMap { (key, value) -> (Int, [ShiftRecord])? in
                guard let k = key else { return nil }
                return (k, value.sortedByName())
            }
            .sorted { $0.0 < $1.0 }
            .map { RecordSection(id: "tent-\($0.0)", title: "Telk \($0.0)", records: $0.1) }

        var result = numbered
        if let ghost = groups[nil]?.sortedByName(), !ghost.isEmpty {
            result.append(RecordSection(id: "tent-none", title: "Telgita", records: ghost))
        }
        return result
    }

    fileprivate func sortedByName() -> [ShiftRecord] {
        sorted { $0.childName.localizedCaseInsensitiveCompare($1.childName) == .orderedAscending }
    }
}

enum ShiftRecordsAPI {
    static func fetch(shiftNr: Int) async throws -> [ShiftRecord] {
        var components = URLComponents(
            url: API.baseURL.appendingPathComponent("api/records"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "shiftNr", value: String(shiftNr))]
        guard let url = components.url else {
            throw AuthError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        print("[Records] GET \(url.absoluteString)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("[Records] transport error: \(error)")
            throw AuthError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            print("[Records] non-HTTP response: \(response)")
            throw AuthError.invalidResponse
        }

        let bodyString = String(data: data, encoding: .utf8) ?? "<\(data.count) bytes, non-UTF8>"
        print("[Records] status \(http.statusCode)")
        print("[Records] body: \(bodyString)")

        switch http.statusCode {
        case 200..<300:
            do {
                let envelope = try JSONDecoder().decode(JSendResponse<ShiftRecordsPayload>.self, from: data)
                guard envelope.status == "success", let payload = envelope.data else {
                    print("[Records] JSend envelope not success: status=\(envelope.status) message=\(envelope.message ?? "nil")")
                    throw AuthError.invalidResponse
                }
                print("[Records] decoded \(payload.records.count) record(s)")
                return payload.records
            } catch let error as AuthError {
                throw error
            } catch let DecodingError.keyNotFound(key, ctx) {
                print("[Records] decoding key not found: \(key.stringValue) — \(ctx.debugDescription) path=\(ctx.codingPath.map(\.stringValue))")
                throw AuthError.decoding(DecodingError.keyNotFound(key, ctx))
            } catch let DecodingError.typeMismatch(type, ctx) {
                print("[Records] decoding type mismatch: expected \(type) — \(ctx.debugDescription) path=\(ctx.codingPath.map(\.stringValue))")
                throw AuthError.decoding(DecodingError.typeMismatch(type, ctx))
            } catch let DecodingError.valueNotFound(type, ctx) {
                print("[Records] decoding value not found: \(type) — \(ctx.debugDescription) path=\(ctx.codingPath.map(\.stringValue))")
                throw AuthError.decoding(DecodingError.valueNotFound(type, ctx))
            } catch let DecodingError.dataCorrupted(ctx) {
                print("[Records] decoding data corrupted: \(ctx.debugDescription) path=\(ctx.codingPath.map(\.stringValue))")
                throw AuthError.decoding(DecodingError.dataCorrupted(ctx))
            } catch {
                print("[Records] decoding error: \(error)")
                throw AuthError.decoding(error)
            }
        case 401, 403:
            throw AuthError.invalidCredentials
        default:
            throw AuthError.server(status: http.statusCode)
        }
    }

    static func setPresence(recordId: Int, isPresent: Bool) async throws {
        try await patch(recordId: recordId, body: PresencePatch(isPresent: isPresent), debug: "isPresent=\(isPresent)")
    }

    static func setTent(recordId: Int, tentNr: Int?) async throws {
        try await patch(recordId: recordId, body: TentPatch(tentNr: tentNr), debug: "tentNr=\(tentNr.map(String.init) ?? "null")")
    }

    static func setTeam(recordId: Int, teamId: Int?) async throws {
        try await patch(recordId: recordId, body: TeamPatch(teamId: teamId), debug: "teamId=\(teamId.map(String.init) ?? "null")")
    }

    private static func patch<Body: Encodable>(recordId: Int, body: Body, debug: String) async throws {
        let url = API.baseURL.appendingPathComponent("api/records/\(recordId)")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)

        print("[Records] PATCH \(url.absoluteString) \(debug)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("[Records] PATCH transport error: \(error)")
            throw AuthError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        print("[Records] PATCH status \(http.statusCode) body: \(String(data: data, encoding: .utf8) ?? "<binary>")")

        switch http.statusCode {
        case 200..<300:
            return
        case 401, 403:
            throw AuthError.invalidCredentials
        default:
            throw AuthError.server(status: http.statusCode)
        }
    }
}

private struct PresencePatch: Encodable {
    let isPresent: Bool
}

private struct TentPatch: Encodable {
    let tentNr: Int?

    enum CodingKeys: String, CodingKey { case tentNr }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let tentNr {
            try container.encode(tentNr, forKey: .tentNr)
        } else {
            try container.encodeNil(forKey: .tentNr)
        }
    }
}
private struct TeamPatch: Encodable {
    let teamId: Int?

    enum CodingKeys: String, CodingKey { case teamId }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let teamId {
            try container.encode(teamId, forKey: .teamId)
        } else {
            try container.encodeNil(forKey: .teamId)
        }
    }
}

