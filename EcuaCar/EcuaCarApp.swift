//
//  EcuaCarApp.swift
//  EcuaCar
//
//  Created by Andres Silva on 5/24/26.
//

import SwiftUI

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

// MARK: - Root View (Main Entry Point)
struct RootView: View {
    @EnvironmentObject var authStorage: AuthenticationStorage
    
    var body: some View {
        Group {
            if authStorage.isAuthenticated {
                // Show main content when authenticated
                ContentView()
            } else {
                // Show login when not authenticated
                OnboardingFlow()
            }
        }
        .animation(.easeInOut, value: authStorage.isAuthenticated)
    }
}
