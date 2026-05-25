//
//  ContentView.swift
//  EcuaCar
//
//  Created by Andres Silva on 5/24/26.
//

import SwiftUI
import Combine

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

// MARK: - Placeholder Views
struct CartView: View {
    var body: some View {
        VStack {
            Text("Cart")
                .font(.largeTitle)
        }
    }
}

#Preview {
    ContentView()
}
