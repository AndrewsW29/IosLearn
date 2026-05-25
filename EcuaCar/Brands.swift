//
//  ContentView.swift
//  EcuaCar
//
//  Created by Andres Silva on 5/24/26.
//

import SwiftUI
import Combine

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

#Preview {
    ContentView()
}

