//
//  MainBackGradient.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 10.11.2025.
//

import SwiftUI

struct MainBackGradient: View {
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [Color.color1, Color.color2,Color.color3]), startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

#Preview {
    MainBackGradient()
}
