//
//  AchvmentsView.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 11.11.2025.
//

import SwiftUI

struct AchvmentsView: View {
    @StateObject private var viewModel = AchvmentsViewModel()

    var body: some View {
        ZStack {
            MainBackGradient()
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Text("ACHIEVEMENTS")
                    .lineLimit(1)
                    .font(.system(size: 48, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.goldApp)
                    .minimumScaleFactor(0.5)

                VStack(spacing: 12) {
                    Text("Count medals: \(viewModel.totalMedalsEarned)")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundStyle(.goldApp)
                }

                ScrollView {
                    VStack(spacing: 18) {
                        ForEach(viewModel.orderedMedals, id: \.rawValue) { medal in
                            HStack(spacing: 16) {
                                if let assetName = medal.assetName {
                                    Image(assetName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 70, height: 70)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(medal.displayName.uppercased())
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.goldApp)
                                    
                                    Text("\(viewModel.medalCounts[medal, default: 0]) шт.")
                                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(.goldApp.opacity(0.9))
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(.goldApp.opacity(0.6), lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
            }
            .padding(32)
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}

#Preview {
    AchvmentsView()
}
