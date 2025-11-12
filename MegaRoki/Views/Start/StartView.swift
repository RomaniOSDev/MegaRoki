//
//  StartView.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 10.11.2025.
//

import SwiftUI

struct StartView: View {
    var body: some View {
        ZStack{
            MainBackGradient()
            VStack(spacing: 30){
                
                NavigationLink {
                    JesterView()
                } label: {
                    MainButton(title: "Roki Chron")
                }
                NavigationLink {
                    QuizRokiView()
                } label: {
                    MainButton(title: "Quiz Roki")
                }
                NavigationLink {
                    MatchView()
                } label: {
                    MainButton(title: "Mega Match")
                }

            }.padding()
        }
    }
}

#Preview {
    StartView()
}
