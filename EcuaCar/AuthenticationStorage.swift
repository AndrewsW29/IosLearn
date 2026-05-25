//
//  AuthenticationStorage.swift
//  EcuaCar
//
//  Created by Andres Silva on 5/24/26.
//

import Foundation
import Security
import Combine

// MARK: - Authentication Data Model
struct AuthenticationData: Codable {
    var authToken: String?
    var messageUniqueId: String?
    var xsrfToken: String?
    var xXsrfToken: String?
    var cookie0: String?
    var cookie1: String?
    var cookie2: String?
    var loginTimestamp: Date?
    
    var isValid: Bool {
        guard let authToken = authToken, !authToken.isEmpty else {
            return false
        }
        return true
    }
}

// MARK: - Keychain Storage Manager
@MainActor
class AuthenticationStorage: ObservableObject {
    static let shared = AuthenticationStorage()
    
    @Published var authData: AuthenticationData?
    @Published var isAuthenticated: Bool = false
    
    private let keychainService = "com.ecuacar.auth"
    private let keychainAccount = "user-auth-data"
    
    private init() {
        // Load authentication data on initialization
        loadAuthData()
    }
    
    // MARK: - Store Authentication Headers
    func storeAuthenticationHeaders(from response: URLResponse) {
        guard let httpResponse = response as? HTTPURLResponse else {
            print("⚠️ Invalid response type")
            return
        }
        
        var authData = AuthenticationData()
        authData.loginTimestamp = Date()
        
        // Extract headers
        let headers = httpResponse.allHeaderFields
        
        // 1. Get X-AUTH-TOKEN
        if let authToken = headers["X-AUTH-TOKEN"] as? String {
            authData.authToken = authToken
            print("✅ Stored X-AUTH-TOKEN: \(authToken.prefix(20))...")
        }
        
        // 2. Get message-unique-id
        if let uniqueId = headers["message-unique-id"] as? String {
            authData.messageUniqueId = uniqueId
            print("✅ Stored message-unique-id: \(uniqueId)")
        }
        
        // 3. Parse Set-Cookie headers
        if let setCookieHeaders = httpResponse.value(forHTTPHeaderField: "Set-Cookie") {
            parseCookies(setCookieHeaders, into: &authData)
        }
        
        // Handle multiple Set-Cookie headers (iOS may combine them)
        // Try to get all cookies from the header fields
        let allCookies = headers.filter { key, _ in
            (key as? String)?.lowercased() == "set-cookie"
        }
        
        for (_, value) in allCookies {
            if let cookieString = value as? String {
                parseCookies(cookieString, into: &authData)
            }
        }
        
        // Store the data securely
        self.authData = authData
        saveToKeychain(authData)
        self.isAuthenticated = authData.isValid
    }
    
    // MARK: - Parse Cookies
    private func parseCookies(_ cookieString: String, into authData: inout AuthenticationData) {
        // Split multiple cookies if they're combined
        let cookies = cookieString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        for cookie in cookies {
            if cookie.contains("ec-car-sales-int-uui-cookie-0") {
                authData.cookie0 = cookie
                print("✅ Stored cookie-0")
            } else if cookie.contains("ec-car-sales-int-uui-cookie-1") {
                authData.cookie1 = cookie
                print("✅ Stored cookie-1")
            } else if cookie.contains("ec-car-sales-int-uui-cookie-2") {
                authData.cookie2 = cookie
                print("✅ Stored cookie-2")
            } else if cookie.contains("XSRF-TOKEN") {
                authData.xsrfToken = cookie
                
                // Extract the X-XSRF-TOKEN value (the part after "XSRF-TOKEN=")
                let cookieComponents = cookie.components(separatedBy: ";")
                if let firstComponent = cookieComponents.first {
                    let tokenParts = firstComponent.components(separatedBy: "=")
                    if tokenParts.count > 1 {
                        authData.xXsrfToken = tokenParts[1]
                        print("✅ Stored XSRF-TOKEN and extracted X-XSRF-TOKEN: \(tokenParts[1].prefix(20))...")
                    }
                }
            }
        }
    }
    
    // MARK: - Keychain Operations
    private func saveToKeychain(_ authData: AuthenticationData) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(authData)
            
            // Delete existing item first
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: keychainAccount
            ]
            SecItemDelete(deleteQuery as CFDictionary)
            
            // Add new item
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: keychainAccount,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            
            let status = SecItemAdd(addQuery as CFDictionary, nil)
            
            if status == errSecSuccess {
                print("✅ Authentication data saved to Keychain")
            } else {
                print("⚠️ Failed to save to Keychain: \(status)")
            }
        } catch {
            print("⚠️ Failed to encode auth data: \(error)")
        }
    }
    
    private func loadAuthData() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data {
            do {
                let decoder = JSONDecoder()
                let authData = try decoder.decode(AuthenticationData.self, from: data)
                self.authData = authData
                self.isAuthenticated = authData.isValid
                print("✅ Loaded authentication data from Keychain")
            } catch {
                print("⚠️ Failed to decode auth data: \(error)")
            }
        } else if status == errSecItemNotFound {
            print("ℹ️ No authentication data found in Keychain")
        } else {
            print("⚠️ Keychain error: \(status)")
        }
    }
    
    func clearAuthData() {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        SecItemDelete(deleteQuery as CFDictionary)
        
        self.authData = nil
        self.isAuthenticated = false
        print("✅ Cleared authentication data")
    }
    
    // MARK: - Helper Methods for API Requests
    func getAuthToken() -> String? {
        return authData?.authToken
    }
    
    func getXSRFToken() -> String? {
        return authData?.xXsrfToken
    }
    
    func getMessageUniqueId() -> String? {
        return authData?.messageUniqueId
    }
    
    func getAllCookies() -> [String] {
        var cookies: [String] = []
        
        if let cookie0 = authData?.cookie0 {
            cookies.append(cookie0)
        }
        if let cookie1 = authData?.cookie1 {
            cookies.append(cookie1)
        }
        if let cookie2 = authData?.cookie2 {
            cookies.append(cookie2)
        }
        if let xsrfToken = authData?.xsrfToken {
            cookies.append(xsrfToken)
        }
        
        return cookies
    }
    
    func configureCookiesForRequest(_ request: inout URLRequest) {
        // Add X-AUTH-TOKEN header
        if let authToken = getAuthToken() {
            request.setValue(authToken, forHTTPHeaderField: "X-AUTH-TOKEN")
        }
        
        // Add X-XSRF-TOKEN header
        if let xsrfToken = getXSRFToken() {
            request.setValue(xsrfToken, forHTTPHeaderField: "X-XSRF-TOKEN")
        }
        
        // Add message-unique-id header
        if let uniqueId = getMessageUniqueId() {
            request.setValue(uniqueId, forHTTPHeaderField: "message-unique-id")
        }
        
        // Add all cookies as Cookie header
        let cookies = getAllCookies()
        if !cookies.isEmpty {
            // Extract cookie name=value pairs
            let cookieValues = cookies.compactMap { cookieString -> String? in
                let components = cookieString.components(separatedBy: ";")
                return components.first?.trimmingCharacters(in: .whitespaces)
            }
            
            let cookieHeader = cookieValues.joined(separator: "; ")
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }
    }
}

// MARK: - URLSession Extension for Cookie Handling
extension URLSession {
    static var authenticatedSession: URLSession {
        let configuration = URLSessionConfiguration.default
        // We'll manually handle cookies
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        return URLSession(configuration: configuration)
    }
}
