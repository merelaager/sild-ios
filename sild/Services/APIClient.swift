//
//  APIClient.swift
//  sild
//

import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case server(status: Int)
    case transport(Error)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Unexpected response from the server."
        case .unauthorized:
            return "Incorrect username or password."
        case .server(let status):
            return "Server error (\(status))."
        case .transport(let error):
            return error.localizedDescription
        case .decoding(let error):
            return "Failed to read server response: \(error.localizedDescription)"
        }
    }
}

private struct JSendEnvelope<Payload: Decodable>: Decodable {
    let status: String
    let data: Payload?
    let message: String?
}

enum APIClient {
    static let baseURL = URL(string: "http://localhost:4000")!

    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    static func get<Payload: Decodable>(
        _ path: String,
        query: [URLQueryItem] = [],
        tag: String
    ) async throws -> Payload {
        let request = makeRequest(method: "GET", path: path, query: query, body: Optional<EmptyBody>.none)
        return try await sendDecoding(request, tag: tag)
    }

    static func post<Body: Encodable>(
        _ path: String,
        body: Body,
        tag: String
    ) async throws {
        let request = makeRequest(method: "POST", path: path, body: body)
        try await send(request, tag: tag)
    }

    static func patch<Body: Encodable>(
        _ path: String,
        body: Body,
        tag: String
    ) async throws {
        let request = makeRequest(method: "PATCH", path: path, body: body)
        try await send(request, tag: tag)
    }

    private struct EmptyBody: Encodable {}

    private static func makeRequest<Body: Encodable>(
        method: String,
        path: String,
        query: [URLQueryItem] = [],
        body: Body?
    ) -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        if !query.isEmpty { components.queryItems = query }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? encoder.encode(body)
        }
        return request
    }

    private static func sendDecoding<Payload: Decodable>(_ request: URLRequest, tag: String) async throws -> Payload {
        let data = try await execute(request, tag: tag)
        do {
            let envelope = try decoder.decode(JSendEnvelope<Payload>.self, from: data)
            guard envelope.status == "success", let payload = envelope.data else {
                print("[\(tag)] envelope not success: status=\(envelope.status) message=\(envelope.message ?? "nil")")
                throw APIError.invalidResponse
            }
            return payload
        } catch let error as APIError {
            throw error
        } catch {
            print("[\(tag)] decoding error: \(error)")
            throw APIError.decoding(error)
        }
    }

    private static func send(_ request: URLRequest, tag: String) async throws {
        _ = try await execute(request, tag: tag)
    }

    @discardableResult
    private static func execute(_ request: URLRequest, tag: String) async throws -> Data {
        print("[\(tag)] \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "?")")
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("[\(tag)] transport error: \(error)")
            throw APIError.transport(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        print("[\(tag)] status \(http.statusCode)")
        switch http.statusCode {
        case 200..<300:
            return data
        case 401, 403:
            throw APIError.unauthorized
        default:
            throw APIError.server(status: http.statusCode)
        }
    }
}
