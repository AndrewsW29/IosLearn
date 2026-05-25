//
//  ExampleUsage.swift
//  EcuaCar
//
//  Example usage of AuthenticationStorage and APIService
//

import SwiftUI
import Combine

// MARK: - Example: Car List View with API Integration
struct CarListExampleView: View {
    @StateObject private var viewModel = CarListViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading cars...")
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await viewModel.loadCars()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    List(viewModel.cars) { car in
                        CarRowView(car: car)
                    }
                }
            }
            .navigationTitle("Cars")
            .task {
                await viewModel.loadCars()
            }
        }
    }
}

// MARK: - Car Row View
struct CarRowView: View {
    let car: Car
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(car.name)
                    .font(.headline)
                Text(car.brand)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(car.price, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("\(car.rating, specifier: "%.1f")")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Car List ViewModel
@MainActor
class CarListViewModel: ObservableObject {
    @Published var cars: [Car] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadCars() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: CarListResponse = try await APIService.shared.fetchCars(page: 1, limit: 50)
            cars = response.cars
            print("✅ Loaded \(cars.count) cars")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load cars: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Example: Add to Cart
struct AddToCartExample {
    func addCarToCart(carId: String) async {
        do {
            let response: CartResponse = try await APIService.shared.addToCart(carId: carId)
            if response.success {
                print("✅ Added to cart! Total items: \(response.cartItemCount)")
            }
        } catch APIError.unauthorized {
            print("❌ Session expired - please login again")
        } catch {
            print("❌ Failed to add to cart: \(error)")
        }
    }
}

// MARK: - Example: Custom API Call
extension APIService {
    // Example: Get car details
    func getCarDetails(carId: String) async throws -> CarDetails {
        return try await authenticatedRequest(endpoint: "/cars/\(carId)")
    }
    
    // Example: Update profile
    func updateProfile(name: String, phone: String) async throws -> UserProfile {
        let body = UpdateProfileRequest(name: name, phone: phone)
        return try await authenticatedRequest(endpoint: "/user/profile", method: "PUT", body: body)
    }
    
    // Example: Get wishlist
    func getWishlist() async throws -> WishlistResponse {
        return try await authenticatedRequest(endpoint: "/user/wishlist")
    }
    
    // Example: Add to wishlist
    func addToWishlist(carId: String) async throws -> WishlistResponse {
        let body = ["carId": carId]
        return try await authenticatedRequest(endpoint: "/user/wishlist/add", method: "POST", body: body)
    }
}

// MARK: - Additional Models
struct CarDetails: Codable {
    let id: String
    let name: String
    let brand: String
    let price: Double
    let rating: Double
    let stock: Int
    let description: String
    let features: [String]
    let images: [String]
}

struct UpdateProfileRequest: Codable {
    let name: String
    let phone: String
}

struct WishlistResponse: Codable {
    let items: [Car]
    let totalCount: Int
}

// MARK: - Example: Manual Request with Custom Headers
struct ManualRequestExample {
    func customAPICall() async {
        let authStorage = AuthenticationStorage.shared
        
        guard authStorage.isAuthenticated else {
            print("Not authenticated")
            return
        }
        
        guard let url = URL(string: "http://172.20.96.1:5066/ec-car-sales/api/custom-endpoint") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Automatically adds all auth headers and cookies
        authStorage.configureCookiesForRequest(&request)
        
        // Add custom headers if needed
        request.setValue("custom-value", forHTTPHeaderField: "Custom-Header")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Status code: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
}

// MARK: - Example: Check Auth Status
struct AuthStatusExample {
    func checkAuthenticationStatus() {
        let authStorage = AuthenticationStorage.shared
        
        if authStorage.isAuthenticated {
            print("✅ User is authenticated")
            
            if let token = authStorage.getAuthToken() {
                print("   Token: \(token.prefix(20))...")
            }
            
            if let uniqueId = authStorage.getMessageUniqueId() {
                print("   Unique ID: \(uniqueId)")
            }
            
            if let xsrfToken = authStorage.getXSRFToken() {
                print("   XSRF Token: \(xsrfToken.prefix(20))...")
            }
            
            let cookies = authStorage.getAllCookies()
            print("   Total cookies: \(cookies.count)")
            
            if let timestamp = authStorage.authData?.loginTimestamp {
                print("   Logged in at: \(timestamp)")
            }
        } else {
            print("❌ User is not authenticated")
        }
    }
}

// MARK: - Example: Profile View with User Data
struct EnhancedProfileView: View {
    @EnvironmentObject var authStorage: AuthenticationStorage
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // User Avatar
                Circle()
                    .fill(Color.blue)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(viewModel.profile?.name.prefix(1).uppercased() ?? "U")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                // User Info
                if let profile = viewModel.profile {
                    VStack(spacing: 8) {
                        Text(profile.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(profile.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                // Auth Info (Debug)
                if let authData = authStorage.authData {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Authentication Info")
                            .font(.headline)
                        
                        InfoRow(label: "Token", value: String(authData.authToken?.prefix(20) ?? "N/A"))
                        InfoRow(label: "Unique ID", value: authData.messageUniqueId ?? "N/A")
                        
                        if let timestamp = authData.loginTimestamp {
                            InfoRow(label: "Login Time", value: timestamp.formatted())
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Logout Button
                Button(action: {
                    authStorage.clearAuthData()
                }) {
                    Text("Logout")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 32)
        }
        .task {
            await viewModel.loadProfile()
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    
    func loadProfile() async {
        do {
            profile = try await APIService.shared.fetchUserProfile()
        } catch {
            print("Failed to load profile: \(error)")
        }
    }
}
