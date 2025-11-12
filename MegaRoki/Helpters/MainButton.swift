//
//  MainButton.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 10.11.2025.
//

import SwiftUI

struct MainButton: View {
    var title: String
    var height: CGFloat = 90
    var body: some View {
        ZStack {
            Image(.backForbutton)
                .resizable()
                .aspectRatio(contentMode: .fit)
            Text(title)
                .foregroundStyle(.goldApp)
                .font(.system(size: height / 2, weight: .heavy, design: .monospaced))
                .minimumScaleFactor(0.5)
        }.frame(height: height)
    }
}

#Preview {
    MainButton(title: "Quiz")
}
