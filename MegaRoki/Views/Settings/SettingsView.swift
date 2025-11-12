//
//  SettingsView.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 12.11.2025.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    var body: some View {
        ZStack{
            MainBackGradient()
            VStack(spacing: 40){
                Button {
                    SKStoreReviewController.requestReview()
                } label: {
                    MainButton(title: "Rate app")
                }
                Button {
                    if let url = URL(string: "https://www.termsfeed.com/live/ce8d80ba-b75a-4651-9651-482ff4302bdc") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    MainButton(title: "Terms")
                }
                Button {
                    if let url = URL(string: "https://www.termsfeed.com/live/74f534f5-88ca-492c-be91-bdeb7b10f371") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    MainButton(title: "Privacy")
                }

            }.padding()
        }
    }
}

#Preview {
    SettingsView()
}
