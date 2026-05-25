//
//  ContentView.swift
//  EcuaCar
//
//  Created by Andres Silva on 5/24/26.
//

import SwiftUI
import Combine


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
#Preview {
    ContentView()
}
