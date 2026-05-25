//
//  APIService.swift
//  EcuaCar
//
//  Created by Andres Silva on 5/24/26.
//

import Foundation

// MARK: - API Service for Authenticated Requests
@MainActor
class APIService {
    static let shared = APIService()
    
    private let authStorage = AuthenticationStorage.shared
    private let baseURL = "http://172.20.96.1:5066/ec-car-sales/api"
    
    private init() {}
    
    // MARK: - Generic Authenticated Request
    func authenticatedRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        
        guard authStorage.isAuthenticated else {
            throw APIError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Configure authentication headers and cookies
        authStorage.configureCookiesForRequest(&request)
        
        // Add body if provided
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        // Log request details
        printRequestDetails(request)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Log response details
        printResponseDetails(httpResponse, data: data)
        
        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
            
        case 401:
            // Token expired or invalid - clear auth data
            authStorage.clearAuthData()
            throw APIError.unauthorized
            
        case 403:
            throw APIError.forbidden
            
        case 404:
            throw APIError.notFound
            
        default:
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMsg)
        }
    }
    
    // MARK: - Example API Calls
    
    // Fetch user profile
    func fetchUserProfile() async throws -> UserProfile {
        return try await authenticatedRequest(endpoint: "/user/profile")
    }
    
    // Fetch cars
    func fetchCars(page: Int = 1, limit: Int = 20) async throws -> CarListResponse {
        return try await authenticatedRequest(endpoint: "/cars?page=\(page)&limit=\(limit)")
    }
    
    // Add car to cart
    func addToCart(carId: String) async throws -> CartResponse {
        let body = ["carId": carId]
        return try await authenticatedRequest(endpoint: "/cart/add", method: "POST", body: body)
    }
    
    // MARK: - Logging Helpers
    private func printRequestDetails(_ request: URLRequest) {
        print("📤 API Request:")
        print("   URL: \(request.url?.absoluteString ?? "N/A")")
        print("   Method: \(request.httpMethod ?? "N/A")")
        print("   Headers:")
        request.allHTTPHeaderFields?.forEach { key, value in
            // Don't print full tokens in logs for security
            if key.contains("TOKEN") || key.contains("Cookie") {
                print("      \(key): \(value.prefix(20))...")
            } else {
                print("      \(key): \(value)")
            }
        }
    }
    
    private func printResponseDetails(_ response: HTTPURLResponse, data: Data) {
        print("📥 API Response:")
        print("   Status Code: \(response.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("   Body: \(responseString.prefix(200))...")
        }
    }
}

// MARK: - API Error
enum APIError: Error, LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case serverError(statusCode: Int, message: String)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You are not authenticated. Please log in."
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .forbidden:
            return "You don't have permission to access this resource"
        case .notFound:
            return "Resource not found"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

// MARK: - Example Response Models

struct UserProfile: Codable {
    let id: String
    let name: String
    let email: String
    // Add other fields based on your API
}

struct CarListResponse: Codable {
    let cars: [Car]
    let totalPages: Int
    let currentPage: Int
}

struct Car: Codable, Identifiable {
    let id: String
    let name: String
    let brand: String
    let price: Double
    let rating: Double
    let stock: Int
    let imageUrl: String?
}

struct CartResponse: Codable {
    let success: Bool
    let message: String
    let cartItemCount: Int
}
