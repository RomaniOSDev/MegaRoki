//
//  ContentView.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 10.11.2025.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("coinsBalance") private var totalCoins = 0
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom){
                MainBackGradient()
                Image(.shoot)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                VStack{
                    HStack(alignment: .top){
                        CoinsView(coins: totalCoins)
                        Spacer()
                        
                        VStack{
                            NavigationLink {
                                SettingsView()
                            } label: {
                                Image(.settingsbutton)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 70)
                            }
                            NavigationLink {
                                AchvmentsView()
                            } label: {
                                Image(.achivmentButton)
                                    .resizable()
                                    .frame(width: 88, height: 73)
                            }
                            
                        }
                        
                    }
                    .padding(.top, 40)
                    Spacer()
                    NavigationLink {
                        StartView()
                    } label: {
                        Image(.startbutton)
                            .resizable()
                            .aspectRatio(contentMode: ContentMode.fit)
                            .padding()
                    }
                    
                }.padding()
                
            }.ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}
