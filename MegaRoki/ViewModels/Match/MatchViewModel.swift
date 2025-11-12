//
//  MatchViewModel.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 11.11.2025.
//

import Foundation
import Combine

final class MatchViewModel: ObservableObject {
    enum GameState: Equatable {
        case levelSelection
        case playing
        case completed(success: Bool)
    }

    static let medalCountsDidChangeNotification = Notification.Name("MatchViewModelMedalCountsDidChange")

    enum Medal: String, Codable, CaseIterable {
        case none
        case bronze
        case silver
        case gold
        case diamond

        var image: ImageResource{
            switch self {
                
            case .none:
                    .noneMedal
            case .bronze:
                    .bronzeMedal
            case .silver:
                    .silverMedal
            case .gold:
                    .goldMedal
            case .diamond:
                    .diamondMedal
            }
        }
        
        var displayName: String {
            switch self {
            case .none:
                return "No medal"
            case .bronze:
                return "Bronza"
            case .silver:
                return "Silver"
            case .gold:
                return "Gold"
            case .diamond:
                return "brilliant"
            }
        }

        var rank: Int {
            switch self {
            case .none:
                return 0
            case .bronze:
                return 1
            case .silver:
                return 2
            case .gold:
                return 3
            case .diamond:
                return 4
            }
        }

        static func medal(for remainingSeconds: Int) -> Medal {
            switch remainingSeconds {
            case 25...:
                return .diamond
            case 20..<25:
                return .gold
            case 15..<20:
                return .silver
            case 10..<15:
                return .bronze
            default:
                return .none
            }
        }
    }

    struct LevelProgress: Identifiable, Codable {
        let id: Int
        var isUnlocked: Bool
        var bestMedal: Medal
    }

    struct Card: Identifiable, Equatable {
        let id: UUID
        let content: String
        var isFaceUp: Bool = false
        var isMatched: Bool = false
    }

    @Published private(set) var levels: [LevelProgress]
    @Published private(set) var cards: [Card] = []
    @Published private(set) var gameState: GameState = .levelSelection
    @Published private(set) var timeRemaining: Int = MatchViewModel.totalTime
    @Published private(set) var earnedMedal: Medal = .none
    @Published private(set) var lastTimeRemaining: Int = 0
    @Published private(set) var isBoardInteractionDisabled = false
    @Published private(set) var medalCounts: [Medal: Int]

    private var currentLevelIndex: Int?
    private var unmatchedPairIndices: [Int] = []
    private var timerSubscription: AnyCancellable?

    private static let totalTime = 40
    private static let storageKey = "match_levels_progress"
    private static let medalCountsKey = "match_medal_counts"
    private static let availableSymbols = [
        "🍎", "🍌", "🍇", "🍒", "🥝", "🍍",
        "🥥", "🍉", "🍑", "🍓", "🍋", "🥭",
        "🥕", "🍆", "🌶", "🥦", "🥑", "🥔"
    ]

    init() {
        levels = Self.loadProgress()
        medalCounts = MatchViewModel.loadMedalCounts()
    }

    deinit {
        stopTimer()
    }

    // MARK: - Public API

    func startLevel(_ levelId: Int) {
        guard let index = levels.firstIndex(where: { $0.id == levelId }),
              levels[index].isUnlocked else { return }

        currentLevelIndex = index
        setupDeck()
        timeRemaining = Self.totalTime
        earnedMedal = .none
        lastTimeRemaining = 0
        unmatchedPairIndices = []
        isBoardInteractionDisabled = false
        gameState = .playing

        startTimer()
    }

    func handleCardSelection(_ cardId: UUID) {
        guard case .playing = gameState else { return }
        guard !isBoardInteractionDisabled,
              let index = cards.firstIndex(where: { $0.id == cardId }),
              !cards[index].isFaceUp,
              !cards[index].isMatched else { return }

        cards[index].isFaceUp = true
        unmatchedPairIndices.append(index)

        if unmatchedPairIndices.count == 2 {
            evaluateSelection()
        }
    }

    func backToLevelSelection() {
        stopTimer()
        resetForSelection()
    }

    func replayCurrentLevel() {
        guard let levelIndex = currentLevelIndex else {
            resetForSelection()
            return
        }
        startLevel(levels[levelIndex].id)
    }

    func advanceToNextLevel() {
        guard case .completed(let success) = gameState, success,
              let levelIndex = currentLevelIndex,
              levelIndex + 1 < levels.count,
              levels[levelIndex + 1].isUnlocked else {
            return
        }
        startLevel(levels[levelIndex + 1].id)
    }

    // MARK: - Helpers

    var currentLevelNumber: Int? {
        guard let index = currentLevelIndex else { return nil }
        return levels[index].id
    }

    var nextLevelIsAvailable: Bool {
        guard let levelIndex = currentLevelIndex else { return false }
        let nextIndex = levelIndex + 1
        guard nextIndex < levels.count else { return false }
        return levels[nextIndex].isUnlocked
    }

    var lastCompletionWasSuccess: Bool {
        guard case .completed(let success) = gameState else { return false }
        return success
    }

    // MARK: - Private

    private func setupDeck() {
        let pairsCount = 6
        var symbols = Self.availableSymbols.shuffled()
        if symbols.count < pairsCount {
            symbols.append(contentsOf: symbols)
        }
        let selected = Array(symbols.prefix(pairsCount))
        var deck = (selected + selected).shuffled()

        cards = deck.map { Card(id: UUID(), content: $0) }
    }

    private func evaluateSelection() {
        guard unmatchedPairIndices.count == 2 else { return }

        let firstIndex = unmatchedPairIndices[0]
        let secondIndex = unmatchedPairIndices[1]

        if cards[firstIndex].content == cards[secondIndex].content {
            cards[firstIndex].isMatched = true
            cards[secondIndex].isMatched = true
            unmatchedPairIndices.removeAll()
            checkForCompletion()
        } else {
            isBoardInteractionDisabled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                guard let self else { return }
                self.cards[firstIndex].isFaceUp = false
                self.cards[secondIndex].isFaceUp = false
                self.unmatchedPairIndices.removeAll()
                self.isBoardInteractionDisabled = false
            }
        }
    }

    private func checkForCompletion() {
        let allMatched = cards.allSatisfy { $0.isMatched }
        if allMatched {
            completeLevel(success: true)
        }
    }

    private func startTimer() {
        stopTimer()
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.handleTick()
            }
    }

    private func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }

    private func handleTick() {
        guard case .playing = gameState else { return }
        guard timeRemaining > 0 else {
            completeLevel(success: false)
            return
        }
        timeRemaining -= 1

        if timeRemaining == 0 {
            completeLevel(success: false)
        }
    }

    private func completeLevel(success: Bool) {
        guard case .playing = gameState else { return }

        stopTimer()
        isBoardInteractionDisabled = true
        lastTimeRemaining = timeRemaining

        if success {
            earnedMedal = Medal.medal(for: timeRemaining)
            updateProgressAfterSuccess()
            recordMedal(earnedMedal)
        } else {
            earnedMedal = .none
        }

        gameState = .completed(success: success)
    }

    private func updateProgressAfterSuccess() {
        guard let levelIndex = currentLevelIndex else { return }

        let medal = earnedMedal
        if medal.rank > levels[levelIndex].bestMedal.rank {
            levels[levelIndex].bestMedal = medal
        }

        let nextIndex = levelIndex + 1
        if nextIndex < levels.count && !levels[nextIndex].isUnlocked {
            levels[nextIndex].isUnlocked = true
        }

        saveProgress()
    }

    private func recordMedal(_ medal: Medal) {
        guard medal != .none else { return }
        medalCounts[medal, default: 0] += 1
        saveMedalCounts()
        NotificationCenter.default.post(name: MatchViewModel.medalCountsDidChangeNotification, object: nil)
    }

    private func resetForSelection() {
        gameState = .levelSelection
        cards = []
        currentLevelIndex = nil
        unmatchedPairIndices.removeAll()
        timeRemaining = Self.totalTime
        earnedMedal = .none
        lastTimeRemaining = 0
        isBoardInteractionDisabled = false
    }

    private func saveProgress() {
        guard let data = try? JSONEncoder().encode(levels) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func saveMedalCounts() {
        let rawCounts = medalCounts.reduce(into: [String: Int]()) { partialResult, entry in
            partialResult[entry.key.rawValue] = entry.value
        }
        guard let data = try? JSONEncoder().encode(rawCounts) else { return }
        UserDefaults.standard.set(data, forKey: Self.medalCountsKey)
    }

    private static func loadProgress() -> [LevelProgress] {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let stored = try? JSONDecoder().decode([LevelProgress].self, from: data),
           stored.count == 10 {
            return stored
        }

        return (1...10).map { index in
            LevelProgress(id: index, isUnlocked: index == 1, bestMedal: .none)
        }
    }

    static func loadMedalCounts() -> [Medal: Int] {
        var counts = Medal.allCases.reduce(into: [Medal: Int]()) { partialResult, medal in
            if medal != .none {
                partialResult[medal] = 0
            }
        }

        guard let data = UserDefaults.standard.data(forKey: medalCountsKey),
              let rawCounts = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return counts
        }

        rawCounts.forEach { key, value in
            if let medal = Medal(rawValue: key), medal != .none {
                counts[medal] = value
            }
        }

        return counts
    }

    static func currentMedalCounts() -> [Medal: Int] {
        loadMedalCounts()
    }
}

extension MatchViewModel.Medal {
    var assetName: String? {
        switch self {
        case .none:
            return nil
        case .bronze:
            return "bronzeMedal"
        case .silver:
            return "silverMedal"
        case .gold:
            return "goldMedal"
        case .diamond:
            return "diamondMedal"
        }
    }
}


