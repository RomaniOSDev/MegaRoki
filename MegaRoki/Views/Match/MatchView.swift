//
//  MatchView.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 11.11.2025.
//

import SwiftUI

struct MatchView: View {
    @StateObject private var viewModel = MatchViewModel()
    @Environment(\.dismiss) var dismiss

    private let cardColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ZStack {
            MainBackGradient()
                .ignoresSafeArea()

            Group {
                switch viewModel.gameState {
                case .levelSelection:
                    levelSelectionView
                case .playing, .completed:
                    playingView
                }
            }
            .padding(24)

            if case .completed(let success) = viewModel.gameState {
                completionOverlay(success: success)
            }
        }
        .animation(.easeInOut, value: viewModel.gameState)
        .navigationBarBackButtonHidden()
    }

    private var levelSelectionView: some View {
        VStack(spacing: 32) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(.backButton)
                        .resizable()
                        .frame(width: 78, height: 62)
                }
                Spacer()
                Text("MEGA MATCH")
                    .font(.system(size: 40, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.goldApp)
            }

            Spacer()

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)],
                      spacing: 16) {
                ForEach(viewModel.levels) { level in
                    Button {
                        viewModel.startLevel(level.id)
                    } label: {
                        LevelCell(level: level)
                    }
                    .disabled(!level.isUnlocked)
                    .opacity(level.isUnlocked ? 1 : 0.5)
                }
            }
            Spacer()
        }
    }

    private var playingView: some View {
        VStack(spacing: 20) {
           
            HStack {
                Button {
                    viewModel.backToLevelSelection()
                } label: {
                    Image(.backButton)
                        .resizable()
                        .frame(width: 78, height: 62)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let level = viewModel.currentLevelNumber {
                        Text("Level \(level)")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(.goldApp)
                    }
                    
                }
            }

            Spacer()
            LazyVGrid(columns: cardColumns, spacing: 12) {
                ForEach(viewModel.cards) { card in
                    CardView(card: card)
                        .onTapGesture {
                            viewModel.handleCardSelection(card.id)
                        }
                        .allowsHitTesting(!viewModel.isBoardInteractionDisabled)
                }
            }

            Spacer()
            ZStack {
                Image(.redRectangl)
                    .resizable()
                    .frame(width: 110, height: 50)
                Text("\(viewModel.timeRemaining)")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(viewModel.timeRemaining > 10 ? .goldApp : .red)
            }
        }
    }

    @ViewBuilder
    private func completionOverlay(success: Bool) -> some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(.winLabel)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Image(viewModel.earnedMedal.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                

                VStack(spacing: 12) {
                    Button {
                        viewModel.replayCurrentLevel()
                    } label: {
                        MainButton(title: "REPITE", height: 80)
                    }

                    if success && viewModel.nextLevelIsAvailable {
                        Button {
                            viewModel.advanceToNextLevel()
                        } label: {
                            MainButton(title: "NEXT", height: 80)
                        }
                    }

                    Button {
                        viewModel.backToLevelSelection()
                    } label: {
                        MainButton(title: "CHOOOSE", height: 80)
                    }
                }
            }
            .padding()
        }
    }
}

private struct LevelCell: View {
    let level: MatchViewModel.LevelProgress

    var body: some View {
        ZStack(alignment: .topTrailing) {
                if level.isUnlocked {
                    Image(.levelComplited)
                        .resizable()
                        .frame(width: 100, height: 100)
                } else {
                    ZStack(alignment: .topTrailing){
                        Image(.backLevelCell)
                            .resizable()
                            .frame(width: 100, height: 100)
                        
                        HStack {
                            Spacer()
                            Text("\(level.id)")
                                .font(.system(size: 72, weight: .heavy, design: .monospaced))
                                .foregroundStyle(.goldApp)
                            Spacer()
                        }
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .foregroundStyle(.goldApp)
                            .padding(6)
                    }
                }
            if let assetName = level.bestMedal.assetName {
                Image(assetName)
                    .resizable()
                    .frame(width: 31, height: 48)
            }
        }
    }
}

private struct CardView: View {
    let card: MatchViewModel.Card

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(card.isFaceUp || card.isMatched ? Color.white.opacity(0.9) : Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.goldApp, lineWidth: card.isFaceUp || card.isMatched ? 3 : 1)
                )

            if card.isFaceUp || card.isMatched {
                Text(card.content)
                    .font(.system(size: 48))
            } else {
                Text("?")
                    .font(.system(size: 42, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.goldApp)
            }
        }
        .frame(height: 110)
        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 4)
    }
}

#Preview {
    MatchView()
}
