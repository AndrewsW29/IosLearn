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

#Preview {
    ContentView()
}


