//
//  QuizRokiView.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 10.11.2025.
//

import SwiftUI

struct QuizRokiView: View {
    @State private var selectedDifficulty: Difficulty?
    @State private var activeQuestions: [QuizQuestion] = []
    @State private var currentQuestionIndex = 0
    @State private var coins = 0
    @State private var selectedAnswerIndex: Int?
    @State private var isAnsweringDisabled = false
    @State private var showCompletion = false
    @State private var lastAnswerDelta: Int?
    @AppStorage("coinsBalance") private var storedCoins = 0

    var body: some View {
        ZStack {
            MainBackGradient()
            content
                .padding(24)
            if showCompletion {
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.7)
                    Image(.shoot)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    VStack {
                        VStack(spacing: 0){
                            Image(.winLabel)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 90)
                            CoinsView(coins: coins)
                        }
                        Spacer()
                        if let difficulty = selectedDifficulty {
                            Button {
                                selectDifficulty(difficulty)
                            } label: {
                                MainButton(title: "RESET")
                            }
                        }
                        Button {
                            resetToDifficultySelection()
                        } label: {
                            MainButton(title: "NEXT")
                        }

                    }.padding(50)
                }.ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let difficulty = selectedDifficulty, let question = currentQuestion {
            quizContent(for: difficulty, question: question)
        } else {
            difficultySelectionView
        }
    }

    private var currentQuestion: QuizQuestion? {
        guard activeQuestions.indices.contains(currentQuestionIndex) else { return nil }
        return activeQuestions[currentQuestionIndex]
    }

    private var difficultySelectionView: some View {
        VStack(spacing: 24) {
            Text("QUIZ ROKI")
                .font(.system(size: 60, weight: .heavy, design: .monospaced))
                .foregroundStyle(.goldApp)
            Spacer()
            ForEach(Difficulty.allCases) { difficulty in
                Button {
                    selectDifficulty(difficulty)
                } label: {
                    MainButton(title: difficulty.displayLabel, height: 100)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func quizContent(for difficulty: Difficulty, question: QuizQuestion) -> some View {
        VStack(spacing: 20) {
            HStack {
                Button {
                    resetToDifficultySelection()
                } label: {
                    Image(.backButton)
                        .resizable()
                        .frame(width: 78, height: 62)
                }
                Spacer()
                if let delta = lastAnswerDelta {
                    Text(delta > 0 ? "+\(delta)" : "\(delta)")
                        .font(.system(size: 40, weight: .heavy, design: .monospaced))
                        .foregroundStyle(delta > 0 ? Color.green : Color.red)
                        .transition(.opacity.combined(with: .scale))
                }
                CoinsView(coins: coins,height: 50)
                
            }
            
            Spacer()
            ZStack {
                Image(.backQuestions)
                    .resizable()
                    .frame(width: 340, height: 300)
                VStack {
                   
                    Text(question.prompt)
                        .font(.system(size: 53, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.goldApp)
                        .minimumScaleFactor(0.5)
                    Text("\(currentQuestionIndex + 1)/\(activeQuestions.count)")
                        .font(.title)
                        .foregroundStyle(.goldApp)
                        .padding(8)
                        .background {
                            Image(.redRectangl)
                                .resizable()
                        }
                }.padding()
                
            }
            VStack(spacing: 16) {
                ForEach(question.options.indices, id: \.self) { index in
                    answerButton(for: index, question: question)
                }
            }
            Spacer()
        }
        .navigationBarBackButtonHidden()
    }

    private func answerButton(for index: Int, question: QuizQuestion) -> some View {
        let isSelected = selectedAnswerIndex == index
        let shouldHighlight = selectedAnswerIndex != nil
        let isCorrect = index == question.correctIndex
        let borderColor: Color

        if shouldHighlight {
            if isCorrect {
                borderColor = .green
            } else if isSelected {
                borderColor = .red
            } else {
                borderColor = .clear
            }
        } else {
            borderColor = .clear
        }

        return Button {
            handleAnswer(index)
        } label: {
            QuestionButtonView(title: question.options[index], height: 82, color: borderColor)
        }
        .disabled(isAnsweringDisabled)
        .animation(.easeInOut(duration: 0.2), value: selectedAnswerIndex)
    }

    private func selectDifficulty(_ difficulty: Difficulty) {
        selectedDifficulty = difficulty
        activeQuestions = difficulty.questions
        currentQuestionIndex = 0
        coins = 0
        selectedAnswerIndex = nil
        isAnsweringDisabled = false
        showCompletion = false
        lastAnswerDelta = nil
    }

    private func resetToDifficultySelection() {
        selectedDifficulty = nil
        activeQuestions = []
        currentQuestionIndex = 0
        coins = 0
        selectedAnswerIndex = nil
        isAnsweringDisabled = false
        showCompletion = false
        lastAnswerDelta = nil
    }

    private func handleAnswer(_ index: Int) {
        guard !isAnsweringDisabled, let question = currentQuestion else { return }
        isAnsweringDisabled = true
        selectedAnswerIndex = index

        let delta = index == question.correctIndex ? 20 : -20
        coins += delta
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            lastAnswerDelta = delta
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let isLastQuestion = currentQuestionIndex >= activeQuestions.count - 1
            if isLastQuestion {
                storedCoins += max(coins, 0)
                showCompletion = true
            } else {
                currentQuestionIndex += 1
                selectedAnswerIndex = nil
                isAnsweringDisabled = false
            }
            withAnimation(.easeOut(duration: 0.2)) {
                lastAnswerDelta = nil
            }
        }
    }
}

extension QuizRokiView {
    struct QuizQuestion: Identifiable {
        let id: Int
        let prompt: String
        let options: [String]
        let correctIndex: Int
    }

    enum Difficulty: String, CaseIterable, Identifiable {
        case easy
        case medium
        case hard

        var id: String { rawValue }

        var displayLabel: String {
            switch self {
            case .easy:
                return "EASY"
            case .medium:
                return "MEDIUM"
            case .hard:
                return "HARD"
            }
        }

        var accentColor: Color {
            switch self {
            case .easy:
                return .green
            case .medium:
                return .yellow
            case .hard:
                return .red
            }
        }

        var questions: [QuizQuestion] {
            switch self {
            case .easy:
                return Difficulty.easyQuestions
            case .medium:
                return Difficulty.mediumQuestions
            case .hard:
                return Difficulty.hardQuestions
            }
        }
    }
}

private extension QuizRokiView.Difficulty {
    static let easyQuestions: [QuizRokiView.QuizQuestion] = [
        QuizRokiView.QuizQuestion(id: 1, prompt: "What color is a banana?", options: ["Yellow", "Blue", "Red"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 2, prompt: "What grows on an apple tree?", options: ["Pears", "Apples", "Plums"], correctIndex: 1),
        QuizRokiView.QuizQuestion(id: 3, prompt: "Who loves bananas the most?", options: ["Monkey", "Cat", "Bear"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 4, prompt: "Which fruit looks like the sun?", options: ["Orange", "Watermelon", "Kiwi"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 5, prompt: "Who’s the funniest fruit in the garden?", options: ["Roki", "Hedgehog", "Fox"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 6, prompt: "Which fruit is green and sour?", options: ["Lemon", "Kiwi", "Pear"], correctIndex: 1),
        QuizRokiView.QuizQuestion(id: 7, prompt: "Which fruit wears a crown?", options: ["Pineapple", "Mango", "Grape"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 8, prompt: "Who’s sweet but not candy?", options: ["Mango", "Cucumber", "Pepper"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 9, prompt: "What grows on a watermelon plant?", options: ["Fruits", "Rocks", "Flowers"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 10, prompt: "What color is a strawberry?", options: ["Red", "Purple", "Blue"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 11, prompt: "What do fruits need to grow?", options: ["Sun", "Shade", "Milk"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 12, prompt: "Who has yellow skin and white inside?", options: ["Banana", "Lemon", "Peach"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 13, prompt: "Who buzzes around the garden?", options: ["Bee", "Fox", "Bird"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 14, prompt: "Which fruit looks like a light bulb?", options: ["Pear", "Plum", "Apple"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 15, prompt: "Which fruit rolls like a ball?", options: ["Watermelon", "Grape", "Orange"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 16, prompt: "What’s yellow and sour?", options: ["Lemon", "Kiwi", "Mango"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 17, prompt: "Which fruit grows in bunches?", options: ["Grapes", "Peach", "Apple"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 18, prompt: "What’s inside a peach?", options: ["A pit", "Seeds", "Water"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 19, prompt: "Which fruit can “smile”?", options: ["Banana", "Pear", "Lemon"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 20, prompt: "Which fruit loves New Year’s Eve?", options: ["Mandarin", "Coconut", "Cherry"], correctIndex: 0)
    ]

    static let mediumQuestions: [QuizRokiView.QuizQuestion] = [
        QuizRokiView.QuizQuestion(id: 21, prompt: "Which fruit has a pit but no bones?", options: ["Peach", "Fish", "Chicken"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 22, prompt: "Who’s green but not a frog?", options: ["Kiwi", "Watermelon", "Lemon"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 23, prompt: "Which fruit smiles when you peel it?", options: ["Banana", "Coconut", "Mango"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 24, prompt: "What does Roki do when a melon falls?", options: ["Laughs", "Cries", "Sleeps"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 25, prompt: "Which fruit grows on a palm tree?", options: ["Date", "Cherry", "Plum"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 26, prompt: "Which fruit loves the sea?", options: ["Coconut", "Peach", "Apple"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 27, prompt: "Who always comes in pairs?", options: ["Cherries", "Pears", "Plums"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 28, prompt: "Which fruit has stripes?", options: ["Watermelon", "Kiwi", "Peach"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 29, prompt: "Who tells the best jokes?", options: ["Roki", "Orange", "Cat"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 30, prompt: "Which fruit looks like a heart?", options: ["Strawberry", "Pear", "Plum"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 31, prompt: "Which fruit is the “king of citrus”?", options: ["Orange", "Lemon", "Lime"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 32, prompt: "Which word is both a fruit and a color?", options: ["Orange", "Banana", "Coconut"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 33, prompt: "Which fruit do pirates love?", options: ["Coconut", "Lemon", "Kiwi"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 34, prompt: "Which fruit is green outside, white inside?", options: ["Kiwi", "Apple", "Mango"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 35, prompt: "Which fruit smells like summer?", options: ["Strawberry", "Cabbage", "Tomato"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 36, prompt: "What does Roki eat for breakfast?", options: ["Pineapple", "Onion", "Carrot"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 37, prompt: "What does a happy fruit do?", options: ["Rolls", "Cries", "Sleeps"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 38, prompt: "Which fruit has stripes on its skin?", options: ["Watermelon", "Mango", "Cherry"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 39, prompt: "Who’s the funniest one at the party?", options: ["Roki", "Lemon", "Apple"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 40, prompt: "What grows on palm trees besides leaves?", options: ["Coconuts", "Pears", "Oranges"], correctIndex: 0)
    ]

    static let hardQuestions: [QuizRokiView.QuizQuestion] = [
        QuizRokiView.QuizQuestion(id: 41, prompt: "What’s the biggest berry in the world?", options: ["Watermelon", "Strawberry", "Cherry"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 42, prompt: "What is juice made from?", options: ["Fruits", "Stones", "Sand"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 43, prompt: "Where do bananas come from?", options: ["India", "Russia", "Canada"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 44, prompt: "Which berry grows on a bush?", options: ["Currant", "Mango", "Melon"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 45, prompt: "Which fruit helps you when you’re sick?", options: ["Orange", "Watermelon", "Apple"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 46, prompt: "Which fruit comes from Africa?", options: ["Watermelon", "Peach", "Apple"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 47, prompt: "What does Roki do when he wins a round?", options: ["Dances", "Sleeps", "Hides"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 48, prompt: "Which fruit looks like a pine cone?", options: ["Pineapple", "Coconut", "Plum"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 49, prompt: "What happens if you plant a joke?", options: ["Laughter", "Tree", "Melon"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 50, prompt: "Which fruit has a little tail?", options: ["Apple", "Pear", "Peach"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 51, prompt: "Which fruit is soft outside and has a pit inside?", options: ["Peach", "Coconut", "Lemon"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 52, prompt: "Which berry can be red, black, or white?", options: ["Currant", "Strawberry", "Cherry"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 53, prompt: "Which berry has tiny “mustaches”?", options: ["Strawberry", "Grape", "Cherry"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 54, prompt: "What’s the sourest fruit?", options: ["Lemon", "Banana", "Kiwi"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 55, prompt: "Which fruit is round, green, and sweet?", options: ["Watermelon", "Orange", "Mango"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 56, prompt: "Which fruit grows in bunches?", options: ["Grapes", "Apples", "Pears"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 57, prompt: "What do fruits need besides sunlight?", options: ["Water", "Milk", "Air"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 58, prompt: "Which berry grows in the forest?", options: ["Blueberry", "Melon", "Grape"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 59, prompt: "What does Roki love most of all?", options: ["Laughter", "Sleep", "Silence"], correctIndex: 0),
        QuizRokiView.QuizQuestion(id: 60, prompt: "Which fruit is “golden” in fairy tales?", options: ["Apple", "Lemon", "Kiwi"], correctIndex: 0)
    ]
}

#Preview {
    QuizRokiView()
}
