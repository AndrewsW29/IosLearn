//
//  DashboardView.swift
//  EcuaCar
//
//  Created by Andres Silva on 5/24/26.
//

import SwiftUI

// MARK: - Dashboard View (Example of using LoginViewModel with APIService)
struct DashboardView: View {
    @EnvironmentObject var authStorage: AuthenticationStorage
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // User Profile Section
                    if viewModel.isLoadingProfile {
                        ProgressView("Loading profile...")
                            .padding()
                    } else if let profile = viewModel.userProfile {
                        userProfileCard(profile)
                    } else {
                        Button("Load Profile") {
                            Task {
                                await viewModel.fetchUserProfile()
                            }
                        }
                        .buttonStyle(.bordered)
                        .padding()
                    }
                    
                    // Authentication Status
                    authStatusCard()
                    
                    // Cars Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Available Cars")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button {
                                Task {
                                    await viewModel.fetchCars()
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .disabled(viewModel.isLoadingCars)
                        }
                        
                        if viewModel.isLoadingCars {
                            ProgressView("Loading cars...")
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if viewModel.cars.isEmpty {
                            Text("No cars available")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.cars) { car in
                                    carCard(car)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
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
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            viewModel.logout()
                        } label: {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .task {
                // Load initial data when view appears
                await viewModel.fetchInitialData()
            }
        }
    }
    
    // MARK: - User Profile Card
    @ViewBuilder
    private func userProfileCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(profile.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Authentication Status Card
    @ViewBuilder
    private func authStatusCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: authStorage.isAuthenticated ? "lock.shield.fill" : "lock.shield")
                    .foregroundColor(authStorage.isAuthenticated ? .green : .red)
                
                Text(authStorage.isAuthenticated ? "Authenticated" : "Not Authenticated")
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if authStorage.isAuthenticated, let remainingTime = authStorage.remainingTime() {
                let minutes = Int(remainingTime / 60)
                let seconds = Int(remainingTime.truncatingRemainder(dividingBy: 60))
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                    
                    Text("Expires in \(minutes)m \(seconds)s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Car Card
    @ViewBuilder
    private func carCard(_ car: Car) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // Car image placeholder
                if let imageUrl = car.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "car")
                                .foregroundColor(.white)
                        )
                }
                
                // Car details
                VStack(alignment: .leading, spacing: 4) {
                    Text(car.name)
                        .font(.headline)
                    
                    Text(car.brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text(String(format: "%.1f", car.rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Stock: \(car.stock)")
                            .font(.caption)
                            .foregroundColor(car.stock > 0 ? .green : .red)
                    }
                    
                    Text("$\(String(format: "%.2f", car.price))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Add to cart button
                Button {
                    Task {
                        let success = await viewModel.addToCart(carId: car.id)
                        if success {
                            print("✅ Added \(car.name) to cart")
                        }
                    }
                } label: {
                    Image(systemName: "cart.badge.plus")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.bordered)
                .disabled(car.stock == 0)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .environmentObject(AuthenticationStorage.shared)
}
