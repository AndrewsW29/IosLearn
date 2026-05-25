//
//  ContentView.swift
//  EcuaCar
//
//  Created by Andres Silva on 5/24/26.
//

import SwiftUI
import Combine

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

#Preview {
    ContentView()
}
