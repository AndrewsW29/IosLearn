//
//  ContentView.swift
//  EcuaCar
//
//  Created by Andres Silva on 5/24/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var authStorage = AuthenticationStorage.shared
    @State private var showOnboarding = true
    
    var body: some View {
        Group {
            if authStorage.isAuthenticated {
                HomeView()
            } else {
                OnboardingFlow()
            }
        }
        .environmentObject(authStorage)
    }
}

// MARK: - Onboarding Flow
struct OnboardingFlow: View {
    @State private var currentPage = 0
    @EnvironmentObject var authStorage: AuthenticationStorage
    
    private let totalPages = 4 // 3 onboarding images + 1 login page
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button (only on onboarding pages)
                if currentPage < 3 {
                    HStack {
                        Spacer()
                        Button("Skip") {
                            withAnimation {
                                currentPage = 3 // Go to login
                            }
                        }
                        .foregroundColor(.gray)
                        .padding(.trailing, 24)
                        .padding(.top, 16)
                    }
                } else {
                    Spacer()
                        .frame(height: 50)
                }
                
                // Page content with animation
                ZStack {
                    // Onboarding page 1
                    OnboardingPageView(
                        imageName: "config/images/1",
                        title: "One stop shop",
                        description: "Discover everything you need in one place. Shop with ease and enjoy a world of endless possibilities!"
                    )
                    .opacity(currentPage == 0 ? 1 : 0)
                    .zIndex(currentPage == 0 ? 1 : 0)
                    
                    // Onboarding page 2
                    OnboardingPageView(
                        imageName: "config/images/2",
                        title: "Convenient shopping",
                        description: "Browse our wide selection and find everything in just a few taps. Your seamless shopping experience starts here!"
                    )
                    .opacity(currentPage == 1 ? 1 : 0)
                    .zIndex(currentPage == 1 ? 1 : 0)
                    
                    // Onboarding page 3
                    OnboardingPageView(
                        imageName: "config/images/3",
                        title: "Instant delivery",
                        description: "Get what you want, when you want it. Speedy deliveries right to your doorstep!"
                    )
                    .opacity(currentPage == 2 ? 1 : 0)
                    .zIndex(currentPage == 2 ? 1 : 0)
                    
                    // Login page
                    LoginPageView()
                        .opacity(currentPage == 3 ? 1 : 0)
                        .zIndex(currentPage == 3 ? 1 : 0)
                }
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                Spacer()
                
                // Bottom navigation (hide on login page)
                if currentPage < 3 {
                    VStack(spacing: 24) {
                        // Page indicators
                        HStack(spacing: 8) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        // Navigation buttons
                        HStack {
                            if currentPage > 0 {
                                Button("Back") {
                                    withAnimation {
                                        currentPage -= 1
                                    }
                                }
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    if currentPage < 2 {
                                        currentPage += 1
                                    } else {
                                        currentPage = 3 // Go to login
                                    }
                                }
                            }) {
                                Text(currentPage < 2 ? "Next" : "Finish")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(25)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let imageName: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Display the image
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .padding(.horizontal, 32)
            
            VStack(spacing: 16) {
                // Title
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                
                // Description
                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Login API Service
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

#Preview {
    ContentView()
}
// MARK: - Home View
struct HomeView: View {
    @State private var selectedTab = 0
    @State private var showAllBrands = false
    @State private var showMostPopular = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content based on selected tab
                switch selectedTab {
                case 0:
                    HomeContentView(showAllBrands: $showAllBrands, showMostPopular: $showMostPopular)
                case 1:
                    CartView()
                case 2:
                    PublicarView()
                case 3:
                    WishListView()
                case 4:
                    ProfileView()
                default:
                    HomeContentView(showAllBrands: $showAllBrands, showMostPopular: $showMostPopular)
                }
                
                // Bottom Navigation Bar
                VStack {
                    Spacer()
                    BottomNavigationBar(selectedTab: $selectedTab)
                }
            }
            .navigationDestination(isPresented: $showAllBrands) {
                AllBrandsView()
            }
            .navigationDestination(isPresented: $showMostPopular) {
                MostPopularView()
            }
        }
    }
}

// MARK: - Home Content View
struct HomeContentView: View {
    @Binding var showAllBrands: Bool
    @Binding var showMostPopular: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    // User avatar
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("L")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Good afternoon")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text("Leon 👋")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    // Search button
                    Button(action: {}) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    .padding(.trailing, 16)
                    
                    // Notification button
                    Button(action: {}) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Banner
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Image("config/images/banner")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 380, height: 180)
                            .clipped()
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 16)
                }
                
                // Page indicators
                HStack(spacing: 6) {
                    Circle().fill(Color.gray.opacity(0.5)).frame(width: 6, height: 6)
                    Circle().fill(Color.blue).frame(width: 6, height: 6)
                    Circle().fill(Color.gray.opacity(0.5)).frame(width: 6, height: 6)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 24)
                
                // Top Brands
                HStack {
                    Text("Top Brands")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        showAllBrands = true
                    }) {
                        Text("See all")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Top Brands Horizontal Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        BrandItem(name: "Mercedes", subtitle: "Autos")
                        BrandItem(name: "Tesla", subtitle: "Autos")
                        BrandItem(name: "BMW", subtitle: "Autos")
                        BrandItem(name: "Toyota", subtitle: "Autos")
                        BrandItem(name: "Volvo", subtitle: "Autos")
                        BrandItem(name: "Bugatti", subtitle: "Autos")
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 32)
                
                // Most Popular
                HStack {
                    Text("Most popular")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button(action: {
                        showMostPopular = true
                    }) {
                        Text("See all")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Car Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    CarCard(name: "Mercedes A-Class Sedan", price: "17438.2", rating: "5.0", stock: "1 in stock")
                    CarCard(name: "Mercedes B-Class", price: "13039.5", rating: "5.0", stock: "1 in stock")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 80)
            }
        }
        .background(Color.white)
    }
}

// MARK: - Brand Item
struct BrandItem: View {
    let name: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.white)
                .frame(width: 70, height: 70)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: brandIcon(for: name))
                        .font(.system(size: 32))
                        .foregroundColor(.black)
                )
            
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.black)
            
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .frame(width: 80)
    }
    
    func brandIcon(for brand: String) -> String {
        switch brand {
        case "Mercedes": return "car.fill"
        case "Tesla": return "bolt.car.fill"
        case "BMW": return "car.circle.fill"
        case "Toyota": return "car.2.fill"
        case "Volvo": return "car.fill"
        case "Bugatti": return "car.fill"
        default: return "car.fill"
        }
    }
}

// MARK: - Car Card
struct CarCard: View {
    let name: String
    let price: String
    let rating: String
    let stock: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with heart icon
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 140)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "car.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue.opacity(0.3))
                    )
                
                Button(action: {}) {
                    Image(systemName: "heart")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                        .padding(12)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text(rating)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black)
                    Text("| \(stock)")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
                
                Text(price)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)
            }
            .padding(12)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Bottom Navigation Bar
struct BottomNavigationBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            TabBarItem(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabBarItem(icon: "cart.fill", title: "Cart", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            TabBarItem(icon: "plus.circle.fill", title: "Publicar", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            
            TabBarItem(icon: "heart.fill", title: "WishList", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
            
            TabBarItem(icon: "person.fill", title: "Profile", isSelected: selectedTab == 4) {
                selectedTab = 4
            }
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - All Brands View
struct AllBrandsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    let brands = ["Mercedes", "Tesla", "BMW", "Toyota", "Volvo", "Bugatti", "Honda"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
                
                Text("All Brands")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.leading, 12)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search brands...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            
            // Brands list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(brands, id: \.self) { brand in
                        BrandRowItem(name: brand)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Brand Row Item
struct BrandRowItem: View {
    let name: String
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.white)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: "car.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                )
            
            Text(name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Most Popular View
struct MostPopularView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPage = 1
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
                
                Text("Most Popular")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.leading, 12)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
            // Car Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(0..<6) { _ in
                        CarCard(name: "Mercedes A-Class Sedan", price: "17438.2", rating: "5.0", stock: "1 in stock")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                
                // Pagination
                HStack(spacing: 12) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Prev")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    }
                    
                    ForEach(1..<5) { page in
                        Button(action: { currentPage = page }) {
                            Text("\(page)")
                                .font(.system(size: 14, weight: page == currentPage ? .bold : .regular))
                                .foregroundColor(page == currentPage ? .white : .black)
                                .frame(width: 35, height: 35)
                                .background(page == currentPage ? Color.blue : Color.clear)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: page == currentPage ? 0 : 1)
                                )
                        }
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Placeholder Views
struct CartView: View {
    var body: some View {
        VStack {
            Text("Cart")
                .font(.largeTitle)
        }
    }
}

struct PublicarView: View {
    var body: some View {
        VStack {
            Text("Publicar")
                .font(.largeTitle)
        }
    }
}

struct WishListView: View {
    var body: some View {
        VStack {
            Text("Wish List")
                .font(.largeTitle)
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authStorage: AuthenticationStorage
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(.largeTitle)
            
            // Display auth info (for debugging)
            if let authData = authStorage.authData {
                VStack(alignment: .leading, spacing: 10) {
                    if let token = authData.authToken {
                        Text("Token: \(token.prefix(20))...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if let uniqueId = authData.messageUniqueId {
                        Text("Unique ID: \(uniqueId)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if let timestamp = authData.loginTimestamp {
                        Text("Logged in: \(timestamp.formatted())")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Logout button
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
            .padding(.bottom, 32)
        }
    }
}

