//
//  OnboardingFlow.swift
//  EcuaCar
//
//  Created by Andres Silva on 5/24/26.
//

import SwiftUI
import Combine

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



#Preview {
    ContentView()
}
