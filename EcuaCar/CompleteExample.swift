//
//  CompleteExample.swift
//  EcuaCar
//
//  Created by Andres Silva on 5/24/26.
//
//  Complete example showing how all components work together
//  NOTE: This is an example file. The actual app entry point is in EcuaCarApp.swift

import SwiftUI

// MARK: - Example App Structure (for reference only)
// Uncomment and use this structure in your actual EcuaCarApp.swift file

/*
@main
struct EcuaCarApp: App {
    @StateObject private var authStorage = AuthenticationStorage.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authStorage)
        }
    }
}
*/

// MARK: - Root View (Main Entry Point)
// NOTE: This is commented out because RootView is now defined in EcuaCarApp.swift
/*
struct RootView: View {
    @EnvironmentObject var authStorage: AuthenticationStorage
    
    var body: some View {
        Group {
            if authStorage.isAuthenticated {
                MainTabView()
            } else {
                LoginPageView()
            }
        }
        .animation(.easeInOut, value: authStorage.isAuthenticated)
    }
}
*/

// MARK: - Main Tab View (After Login)
struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            CarListTab()
                .tabItem {
                    Label("Cars", systemImage: "car.fill")
                }
            
            ProfileTab()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

// MARK: - Car List Tab
struct CarListTab: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var currentPage = 1
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoadingCars {
                    ProgressView("Loading cars...")
                } else {
                    List {
                        ForEach(viewModel.cars) { car in
                            CarRow(car: car, viewModel: viewModel)
                        }
                        
                        // Load more button
                        if !viewModel.cars.isEmpty {
                            Button("Load More") {
                                currentPage += 1
                                Task {
                                    await viewModel.fetchCars(page: currentPage)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .refreshable {
                        currentPage = 1
                        await viewModel.fetchCars(page: 1)
                    }
                }
            }
            .navigationTitle("Available Cars")
            .task {
                await viewModel.fetchCars(page: currentPage)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Car Row
struct CarRow: View {
    let car: Car
    @ObservedObject var viewModel: LoginViewModel
    @State private var isAddingToCart = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Car Image
            carImage
            
            // Car Details
            VStack(alignment: .leading, spacing: 4) {
                Text(car.name)
                    .font(.headline)
                
                Text(car.brand)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    // Rating
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", car.rating))
                    }
                    .font(.caption)
                    
                    Spacer()
                    
                    // Stock
                    HStack(spacing: 4) {
                        Circle()
                            .fill(car.stock > 0 ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(car.stock > 0 ? "In Stock (\(car.stock))" : "Out of Stock")
                            .font(.caption)
                    }
                }
                
                // Price
                Text("$\(String(format: "%.2f", car.price))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Add to Cart Button
            VStack {
                if isAddingToCart {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button {
                        addToCart()
                    } label: {
                        Image(systemName: "cart.badge.plus")
                            .font(.title3)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(car.stock == 0)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var carImage: some View {
        if let imageUrl = car.imageUrl, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholderImage
                @unknown default:
                    placeholderImage
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)
        } else {
            placeholderImage
        }
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 80, height: 80)
            .cornerRadius(8)
            .overlay(
                Image(systemName: "car")
                    .foregroundColor(.white)
            )
    }
    
    private func addToCart() {
        isAddingToCart = true
        Task {
            let success = await viewModel.addToCart(carId: car.id)
            isAddingToCart = false
            
            if success {
                print("✅ Added \(car.name) to cart")
                // Could show a toast notification here
            }
        }
    }
}

// MARK: - Profile Tab
struct ProfileTab: View {
    @EnvironmentObject var authStorage: AuthenticationStorage
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // User Profile Section
                Section("Profile") {
                    if viewModel.isLoadingProfile {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if let profile = viewModel.userProfile {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(profile.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(profile.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("ID: \(profile.id)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    } else {
                        Button("Load Profile") {
                            Task {
                                await viewModel.fetchUserProfile()
                            }
                        }
                    }
                }
                
                // Session Info Section
                Section("Session") {
                    HStack {
                        Text("Status")
                        Spacer()
                        HStack {
                            Circle()
                                .fill(authStorage.isAuthenticated ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(authStorage.isAuthenticated ? "Active" : "Inactive")
                                .foregroundColor(authStorage.isAuthenticated ? .green : .red)
                        }
                    }
                    
                    if authStorage.isAuthenticated, let remaining = authStorage.remainingTime() {
                        SessionTimerRow(remainingTime: remaining)
                    }
                    
                    if let authToken = authStorage.getAuthToken() {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auth Token")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(authToken.prefix(30))...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Actions Section
                Section("Actions") {
                    Button {
                        viewModel.checkAuthStatus()
                    } label: {
                        Label("Check Auth Status", systemImage: "lock.shield")
                    }
                    
                    Button {
                        Task {
                            await viewModel.fetchInitialData()
                        }
                    } label: {
                        Label("Refresh All Data", systemImage: "arrow.clockwise")
                    }
                    
                    Button(role: .destructive) {
                        viewModel.logout()
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .task {
                await viewModel.fetchUserProfile()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Session Timer Row
struct SessionTimerRow: View {
    let remainingTime: TimeInterval
    
    var body: some View {
        HStack {
            Text("Expires in")
            Spacer()
            
            let minutes = Int(remainingTime / 60)
            let seconds = Int(remainingTime.truncatingRemainder(dividingBy: 60))
            
            HStack(spacing: 4) {
                Image(systemName: remainingTime < 60 ? "exclamationmark.triangle.fill" : "clock")
                    .foregroundColor(remainingTime < 60 ? .red : .orange)
                
                Text("\(minutes)m \(seconds)s")
                    .foregroundColor(remainingTime < 60 ? .red : .primary)
                    .monospacedDigit()
            }
        }
    }
}

 

// MARK: - Preview
#Preview("Login Page") {
    LoginPageView()
        .environmentObject(AuthenticationStorage.shared)
}

#Preview("Dashboard") {
    DashboardView()
        .environmentObject(AuthenticationStorage.shared)
}

#Preview("Profile Tab") {
    ProfileTab()
        .environmentObject(AuthenticationStorage.shared)
}
