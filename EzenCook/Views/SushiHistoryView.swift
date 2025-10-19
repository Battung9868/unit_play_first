//
//  SushiHistoryView.swift
//  SparTime
//
//  Created by Assistant on 03/08/2025.
//

import SwiftUI

struct SushiHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Top image
                    Image("item_reset")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .padding(.horizontal, 20)
                    
                    // Facts text
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sushi Facts & History")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("PrimaryText"))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FactItem(number: "1", text: "Fact: Nigiri literally means \"compressed (rice).\" The format originated in Edo (now Tokyo) in the 19th century as a street fast food—large pieces of fish on a ball of rice, perfect for eating on the go.")
                            
                            FactItem(number: "2", text: "Fact: Nori sheets were first made using a technology inspired by Japanese papermaking—seaweed was pressed and dried into thin sheets as early as the 18th century.")
                            
                            FactItem(number: "3", text: "Fact: The key to the taste of sushi is umami. It was described in 1908, isolating glutamate from kombu broth; it is what makes rice, nori, and fish so harmonious.")
                            
                            FactItem(number: "4", text: "Fact: In the classic serving, the sauce is dipped fish-side down to prevent the rice from becoming soggy and maintain a balanced flavor.")
                            
                            FactItem(number: "5", text: "Fact: Sushi rice is the Shinto \"heart\" of the dish. The word shari means rice, and neta means fish/filling; Together they create the right structure and flavor.")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color("Background"))
            .navigationTitle("Sushi History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color("Accent"))
                }
            }
        }
    }
}

struct FactItem: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color("Accent"))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color("Accent").opacity(0.1))
                )
            
            Text(text)
                .font(.body)
                .foregroundColor(Color("PrimaryText"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    SushiHistoryView()
}
