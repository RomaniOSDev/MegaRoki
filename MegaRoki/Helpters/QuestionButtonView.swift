//
//  QuestionButtonView.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 11.11.2025.
//

import SwiftUI

struct QuestionButtonView: View {
    var title: String
    var height: CGFloat
    var color: Color
    var body: some View {
        ZStack {
           Rectangle()
                .foregroundStyle(color)
                .overlay {
                    Rectangle()
                        .stroke(lineWidth: 3)
                        .foregroundStyle(.goldApp)
                }
            Text(title)
                .foregroundStyle(.goldApp)
                .font(.system(size: height / 2, weight: .heavy, design: .monospaced))
        }.frame(height: height)
    }
}

#Preview {
    QuestionButtonView(title: "Good", height: 82, color: .red)
        .padding()
}
