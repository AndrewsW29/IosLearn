//
//  OnboardingFlow.swift
//  EcuaCar
//
//  Created by Andres Silva on 5/24/26.
//

import SwiftUI
import Combine

// MARK: - Login Page View
struct LoginPageView: View {
    @EnvironmentObject var authStorage: AuthenticationStorage
    @StateObject private var viewModel = LoginViewModel()
    @State private var showPassword: Bool = false
    @State private var showAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Title
            Text("Login to your account")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .padding(.bottom, 40)
            
            VStack(spacing: 20) {
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.gray)
                        
                        TextField("", text: $viewModel.email)
                            .textFieldStyle(.plain)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                        
                        if showPassword {
                            TextField("", text: $viewModel.password)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("", text: $viewModel.password)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal, 32)
            
            // Login button
            Button(action: {
                Task {
                    do {
                        try await viewModel.login()
                        // No need to set isLoggedIn - authStorage handles it
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                        showAlert = true
                    }
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(viewModel.isLoading ? "Logging in..." : "Login")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.isLoading ? Color.blue.opacity(0.7) : Color.blue)
                .cornerRadius(12)
            }
            .disabled(viewModel.isLoading)
            .padding(.horizontal, 32)
            .padding(.top, 32)
            
            // Sign up link
            HStack(spacing: 4) {
                Text("Don't have an account")
                    .foregroundColor(.gray)
                
                Button("Sign up") {
                    // Handle sign up
                }
                .foregroundColor(.blue)
            }
            .font(.system(size: 14))
            .padding(.top, 20)
            
            Spacer()
        }
        .background(Color.white)
        .alert("Login Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
}


struct LoginResponse: Codable {
    // The response body can be empty or contain user data
    // The important data comes from headers
}

enum LoginError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Invalid email or password"
        case .serverError(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Published properties for API data
    @Published var userProfile: UserProfile?
    @Published var cars: [Car] = []
    @Published var isLoadingProfile: Bool = false
    @Published var isLoadingCars: Bool = false
    
    private let authStorage = AuthenticationStorage.shared
    private let apiService = APIService.shared
    
    func login() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // Use APIService.Login() method
            let (data, httpResponse) = try await apiService.Login(password: password, email: email)
            
            // Successfully logged in - Store authentication headers
            print("📦 Login successful - storing authentication data...")
            authStorage.storeAuthenticationHeaders(from: httpResponse)
            
            print("✅ Authentication data stored successfully")
            
            // After successful login, optionally fetch initial data
            await fetchInitialData()
            
        } catch APIError.serverError(let statusCode, let message) where statusCode == 401 {
            throw LoginError.unauthorized
        } catch APIError.serverError(let statusCode, let message) {
            throw LoginError.serverError(message)
        } catch APIError.invalidURL {
            throw LoginError.invalidURL
        } catch APIError.invalidResponse {
            throw LoginError.invalidResponse
        } catch {
            throw LoginError.networkError(error)
        }
    }
    
    // MARK: - API Service Methods
    
    /// Fetch initial data after login (user profile and cars)
    func fetchInitialData() async {
        async let profile = fetchUserProfile()
        async let cars = fetchCars()
        
        // Wait for both to complete
        _ = await (profile, cars)
    }
    
    /// Fetch user profile using APIService
    @discardableResult
    func fetchUserProfile() async -> Bool {
        isLoadingProfile = true
        defer { isLoadingProfile = false }
        
        do {
            let profile: UserProfile = try await apiService.fetchUserProfile()
            self.userProfile = profile
            print("✅ User profile loaded: \(profile.name)")
            return true
        } catch APIError.unauthorized {
            // Session expired - clear auth and show login
            errorMessage = "Your session has expired. Please log in again."
            return false
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            print("⚠️ Failed to load user profile: \(error)")
            return false
        }
    }
    
    /// Fetch cars using APIService
    @discardableResult
    func fetchCars(page: Int = 1, limit: Int = 20) async -> Bool {
        isLoadingCars = true
        defer { isLoadingCars = false }
        
        do {
            let response: CarListResponse = try await apiService.fetchCars(page: page, limit: limit)
            self.cars = response.cars
            print("✅ Loaded \(response.cars.count) cars (page \(response.currentPage) of \(response.totalPages))")
            return true
        } catch APIError.unauthorized {
            // Session expired
            errorMessage = "Your session has expired. Please log in again."
            return false
        } catch {
            errorMessage = "Failed to load cars: \(error.localizedDescription)"
            print("⚠️ Failed to load cars: \(error)")
            return false
        }
    }
    
    /// Add a car to cart using APIService
    func addToCart(carId: String) async -> Bool {
        do {
            let response: CartResponse = try await apiService.addToCart(carId: carId)
            print("✅ Added to cart: \(response.message)")
            return response.success
        } catch APIError.unauthorized {
            errorMessage = "Your session has expired. Please log in again."
            return false
        } catch {
            errorMessage = "Failed to add to cart: \(error.localizedDescription)"
            print("⚠️ Failed to add to cart: \(error)")
            return false
        }
    }
    
    /// Check authentication status and remaining time
    func checkAuthStatus() {
        if authStorage.isAuthenticated {
            if let remainingTime = authStorage.remainingTime() {
                let minutes = Int(remainingTime / 60)
                let seconds = Int(remainingTime.truncatingRemainder(dividingBy: 60))
                print("🔐 Authentication valid for \(minutes)m \(seconds)s")
            }
        } else {
            print("⚠️ Not authenticated or session expired")
        }
    }
    
    /// Logout and clear all data
    func logout() {
        authStorage.clearAuthData()
        userProfile = nil
        cars = []
        email = ""
        password = ""
        print("👋 Logged out successfully")
    }
}

