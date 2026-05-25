//
//  ContentView.swift
//  EcuaCar
//
//  Created by Andres Silva on 5/24/26.
//

import SwiftUI
import Combine

@MainActor
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

#Preview {
    ContentView()
}
