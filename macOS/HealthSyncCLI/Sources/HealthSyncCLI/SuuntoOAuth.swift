// Copyright 2026 Marcus Neves
// SPDX-License-Identifier: Apache-2.0

import CryptoKit
import Foundation
import Network
import Security

// MARK: - Token model

struct SuuntoTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}

// MARK: - Keychain helpers

private let keychainService = "com.mneves.HealthSyncCLI.Suunto"
private let keychainAccount = "tokens"

func suuntoLoadTokens() -> SuuntoTokens? {
    let query: [CFString: Any] = [
        kSecClass:           kSecClassGenericPassword,
        kSecAttrService:     keychainService,
        kSecAttrAccount:     keychainAccount,
        kSecReturnData:      true,
        kSecMatchLimit:      kSecMatchLimitOne
    ]
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
          let data = item as? Data else { return nil }
    return try? JSONDecoder().decode(SuuntoTokens.self, from: data)
}

func suuntoSaveTokens(_ tokens: SuuntoTokens) throws {
    let data = try JSONEncoder().encode(tokens)
    let attrs: [CFString: Any] = [
        kSecClass:       kSecClassGenericPassword,
        kSecAttrService: keychainService,
        kSecAttrAccount: keychainAccount,
        kSecValueData:   data
    ]
    SecItemDelete(attrs as CFDictionary)
    let status = SecItemAdd(attrs as CFDictionary, nil)
    guard status == errSecSuccess else {
        throw SuuntoError.keychainError(status)
    }
}

func suuntoDeleteTokens() {
    let attrs: [CFString: Any] = [
        kSecClass:       kSecClassGenericPassword,
        kSecAttrService: keychainService,
        kSecAttrAccount: keychainAccount
    ]
    SecItemDelete(attrs as CFDictionary)
}

// MARK: - Errors

enum SuuntoError: Error, CustomStringConvertible {
    case missingClientID
    case missingClientSecret
    case notAuthenticated
    case oauthCallbackTimeout
    case oauthCallbackError(String)
    case tokenExchangeFailed(String)
    case refreshFailed(String)
    case keychainError(OSStatus)
    case apiError(Int, String)

    var description: String {
        switch self {
        case .missingClientID:           return "Set SUUNTO_CLIENT_ID environment variable."
        case .missingClientSecret:       return "Set SUUNTO_CLIENT_SECRET environment variable."
        case .notAuthenticated:          return "Not authenticated. Run: healthsync suunto auth"
        case .oauthCallbackTimeout:      return "OAuth callback timed out (90 s). Did you complete the browser flow?"
        case .oauthCallbackError(let e): return "OAuth error from Suunto: \(e)"
        case .tokenExchangeFailed(let e):return "Token exchange failed: \(e)"
        case .refreshFailed(let e):      return "Token refresh failed: \(e)"
        case .keychainError(let s):      return "Keychain error \(s)"
        case .apiError(let c, let m):    return "Suunto API error \(c): \(m)"
        }
    }
}

// MARK: - PKCE helpers

private func pkceVerifier() -> String {
    var bytes = [UInt8](repeating: 0, count: 32)
    _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    return Data(bytes).base64URLEncoded()
}

private func pkceChallenge(from verifier: String) -> String {
    let digest = SHA256.hash(data: Data(verifier.utf8))
    return Data(digest).base64URLEncoded()
}

private extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - OAuth endpoints

private let authorizationEndpoint = "https://cloudapi-oauth.suunto.com/oauth/authorize"
private let tokenEndpoint          = "https://cloudapi-oauth.suunto.com/oauth/token"

// MARK: - Local callback server

/// Minimal single-shot HTTP server that captures the OAuth redirect.
final class OAuthCallbackServer {
    private(set) var port: UInt16 = 0
    private var listener: NWListener?
    private var code: String?
    private var returnedState: String?
    private var error: String?
    private let semaphore = DispatchSemaphore(value: 0)
    private let portSemaphore = DispatchSemaphore(value: 0)
    private var listenerFailed = false
    private var handled = false
    private let lock = NSLock()

    init(requestedPort: UInt16 = 0) throws {
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        listener = try NWListener(using: params, on: NWEndpoint.Port(integerLiteral: requestedPort))
    }

    /// Start the listener and block until the OS assigns the actual port (or fails).
    func start() throws {
        listener?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.port = self?.listener?.port?.rawValue ?? 0
                self?.portSemaphore.signal()
            case .failed:
                self?.listenerFailed = true
                self?.portSemaphore.signal()
                self?.semaphore.signal()
            default:
                break
            }
        }
        listener?.newConnectionHandler = { [weak self] conn in
            conn.start(queue: .global())
            conn.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, _, _ in
                guard let data, let request = String(data: data, encoding: .utf8) else { return }
                let line = request.components(separatedBy: "\r\n").first ?? ""
                // GET /callback?code=XXX&state=YYY HTTP/1.1
                if let range = line.range(of: "GET /callback?"),
                   let endRange = line.range(of: " HTTP/") {
                    let query = String(line[range.upperBound..<endRange.lowerBound])
                    var components = URLComponents()
                    components.query = query
                    let items = components.queryItems ?? []
                    self?.lock.lock()
                    guard self?.handled == false else { self?.lock.unlock(); conn.cancel(); return }
                    self?.handled = true
                    if let errItem = items.first(where: { $0.name == "error" }) {
                        self?.error = errItem.value ?? "unknown"
                    } else if let codeItem = items.first(where: { $0.name == "code" }) {
                        self?.code = codeItem.value
                        self?.returnedState = items.first(where: { $0.name == "state" })?.value
                    }
                    self?.lock.unlock()
                }
                let body = "<html><body><h2>Authorized. You can close this window.</h2></body></html>"
                let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
                conn.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
                    conn.cancel()
                    self?.listener?.cancel()
                    self?.semaphore.signal()
                })
            }
        }
        listener?.start(queue: .global())
        portSemaphore.wait()
        if listenerFailed { throw SuuntoError.oauthCallbackError("Could not bind local callback server") }
    }

    func waitForCallback(timeout: TimeInterval = 90) -> Result<(code: String, state: String?), SuuntoError> {
        let result = semaphore.wait(timeout: .now() + timeout)
        listener?.cancel()

        if listenerFailed { return .failure(.oauthCallbackError("Local callback server failed")) }
        if result == .timedOut { return .failure(.oauthCallbackTimeout) }
        if let err = error    { return .failure(.oauthCallbackError(err)) }
        if let code           { return .success((code: code, state: returnedState)) }
        return .failure(.oauthCallbackTimeout)
    }
}

// MARK: - OAuth flow

struct SuuntoOAuthFlow {
    let clientID: String
    let clientSecret: String

    init() throws {
        guard let id = ProcessInfo.processInfo.environment["SUUNTO_CLIENT_ID"], !id.isEmpty else {
            throw SuuntoError.missingClientID
        }
        guard let secret = ProcessInfo.processInfo.environment["SUUNTO_CLIENT_SECRET"], !secret.isEmpty else {
            throw SuuntoError.missingClientSecret
        }
        self.clientID     = id
        self.clientSecret = secret
    }

    func authorize() async throws -> SuuntoTokens {
        let server = try OAuthCallbackServer()
        try server.start()
        let redirectURI = "http://localhost:\(server.port)/callback"
        let verifier    = pkceVerifier()
        let challenge   = pkceChallenge(from: verifier)
        let state       = Data((0..<16).map { _ in UInt8.random(in: 0...255) }).base64URLEncoded()

        var comps        = URLComponents(string: authorizationEndpoint)!
        comps.queryItems = [
            URLQueryItem(name: "response_type",          value: "code"),
            URLQueryItem(name: "client_id",              value: clientID),
            URLQueryItem(name: "redirect_uri",           value: redirectURI),
            URLQueryItem(name: "code_challenge",         value: challenge),
            URLQueryItem(name: "code_challenge_method",  value: "S256"),
            URLQueryItem(name: "scope",                  value: "workout"),
            URLQueryItem(name: "state",                  value: state)
        ]
        let authURL = comps.url!.absoluteString

        print("Opening browser for Suunto authorization...")
        print("If your browser doesn't open, visit:\n  \(authURL)\n")
        Process.launchedProcess(launchPath: "/usr/bin/open", arguments: [authURL])

        let callbackResult = server.waitForCallback()
        switch callbackResult {
        case .failure(let e): throw e
        case .success(let result):
            guard result.state == state else {
                throw SuuntoError.oauthCallbackError("state mismatch — possible CSRF")
            }
            return try await exchangeCode(result.code, verifier: verifier, redirectURI: redirectURI)
        }
    }

    func exchangeCode(_ code: String, verifier: String, redirectURI: String) async throws -> SuuntoTokens {
        var req = URLRequest(url: URL(string: tokenEndpoint)!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = [
            "grant_type":    "authorization_code",
            "client_id":     clientID,
            "client_secret": clientSecret,
            "code":          code,
            "redirect_uri":  redirectURI,
            "code_verifier": verifier
        ].map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
         .joined(separator: "&")
        req.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw SuuntoError.tokenExchangeFailed(String(data: data, encoding: .utf8) ?? "status \(status)")
        }
        return try parseTokenResponse(data)
    }

    func refreshTokens(_ existing: SuuntoTokens) async throws -> SuuntoTokens {
        var req = URLRequest(url: URL(string: tokenEndpoint)!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = [
            "grant_type":    "refresh_token",
            "client_id":     clientID,
            "client_secret": clientSecret,
            "refresh_token": existing.refreshToken
        ].map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
         .joined(separator: "&")
        req.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw SuuntoError.refreshFailed(String(data: data, encoding: .utf8) ?? "status \(status)")
        }
        return try parseTokenResponse(data)
    }

    private func parseTokenResponse(_ data: Data) throws -> SuuntoTokens {
        struct TokenResponse: Decodable {
            let access_token: String
            let refresh_token: String
            let expires_in: Int
        }
        do {
            let raw = try JSONDecoder().decode(TokenResponse.self, from: data)
            return SuuntoTokens(
                accessToken:  raw.access_token,
                refreshToken: raw.refresh_token,
                expiresAt:    Date().addingTimeInterval(TimeInterval(raw.expires_in))
            )
        } catch {
            throw SuuntoError.tokenExchangeFailed("Could not parse token response: \(error)")
        }
    }
}

// MARK: - Token management helper

/// Returns a valid access token, refreshing automatically if expired.
func suuntoAccessToken() async throws -> String {
    guard let tokens = suuntoLoadTokens() else { throw SuuntoError.notAuthenticated }
    if tokens.expiresAt > Date().addingTimeInterval(60) {
        return tokens.accessToken
    }
    let flow      = try SuuntoOAuthFlow()
    let refreshed = try await flow.refreshTokens(tokens)
    try suuntoSaveTokens(refreshed)
    return refreshed.accessToken
}
