//
//  AchvmentsViewModel.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 11.11.2025.
//

import Foundation
import Combine

final class AchvmentsViewModel: ObservableObject {
    @Published private(set) var medalCounts: [MatchViewModel.Medal: Int] = [:]

    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        medalCounts = MatchViewModel.currentMedalCounts()
        notificationCenter.addObserver(self,
                                       selector: #selector(handleMedalCountsChanged),
                                       name: MatchViewModel.medalCountsDidChangeNotification,
                                       object: nil)
    }

    deinit {
        notificationCenter.removeObserver(self,
                                          name: MatchViewModel.medalCountsDidChangeNotification,
                                          object: nil)
    }

    func refresh() {
        medalCounts = MatchViewModel.currentMedalCounts()
    }

    var orderedMedals: [MatchViewModel.Medal] {
        MatchViewModel.Medal.allCases.filter { $0 != .none }.sorted { $0.rank > $1.rank }
    }

    var totalMedalsEarned: Int {
        medalCounts.values.reduce(0, +)
    }

    @objc
    private func handleMedalCountsChanged() {
        refresh()
    }
}


