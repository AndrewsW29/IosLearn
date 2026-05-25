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

// MARK: - Login API Models and ViewModel
struct LoginRequest: Codable {
    let email: String
    let password: String
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
    
    private let authStorage = AuthenticationStorage.shared
    
    func login() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "http://192.168.2.9:80/ec-car-sales/api/public/login") else {
            throw LoginError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginRequest = LoginRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(loginRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LoginError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                // Successfully logged in - Store authentication headers
                print("📦 Login successful - storing authentication data...")
                authStorage.storeAuthenticationHeaders(from: httpResponse)
                
                // Optional: decode response body if needed
                // let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                
                print("✅ Authentication data stored successfully")
                return
                
            case 401:
                throw LoginError.unauthorized
                
            default:
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw LoginError.serverError(errorMsg)
            }
        } catch let error as LoginError {
            throw error
        } catch {
            throw LoginError.networkError(error)
        }
    }
}

