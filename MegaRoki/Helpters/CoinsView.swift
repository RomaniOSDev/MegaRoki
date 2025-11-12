//
//  CoinsView.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 10.11.2025.
//

import SwiftUI

struct CoinsView: View {
    var coins: Int
    var height: CGFloat = 80
    var body: some View {
        ZStack{
           Image(.coinsBack)
               .resizable()
               .aspectRatio(contentMode: .fit)
           Text("\(coins)")
                .foregroundStyle(.goldApp)
                .font(.system(size: height/2.5, weight: .bold, design: .monospaced))
                .padding(.leading, 50)
       }.frame(height: height)
    }
}

#Preview {
    CoinsView(coins: 580)
}
