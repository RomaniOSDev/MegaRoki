//
//  JesterViewModel.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 12.11.2025.
//

import Foundation
import Combine

@MainActor
final class JesterViewModel: ObservableObject {
    struct JesterItem: Identifiable, Equatable {
        let id: Int
        let title: String
        let artist: String?
        let date: String?
        let medium: String?
        let department: String?
        let description: String?
        let imageURL: URL?
        let objectURL: URL?
    }

    private enum Constants {
        static let keywords: [String] = [
            "jester",
            "fool",
            "court jester"
        ]
        static let maxItems = 15
        static let baseURL = URL(string: "https://collectionapi.metmuseum.org/public/collection/v1")!
    }

    @Published private(set) var items: [JesterItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func loadIfNeeded() async {
        guard items.isEmpty else { return }
        await load(force: false)
    }

    func reload() async {
        await load(force: true)
    }

    private func load(force: Bool) async {
        if isLoading { return }
        if !force, !items.isEmpty { return }

        isLoading = true
        errorMessage = nil

        do {
            let objectIDs = try await searchObjectIDs()
            let objects = try await fetchObjects(for: objectIDs)
            items = objects.map(Self.makeItem(from:))
        } catch {
            errorMessage = error.localizedDescription
            items = []
        }

        isLoading = false
    }

    private func searchObjectIDs() async throws -> [Int] {
        try await withThrowingTaskGroup(of: (Int, [Int]).self) { group in
            for (index, keyword) in Constants.keywords.enumerated() {
                group.addTask { [urlSession] in
                    let ids = try await Self.fetchObjectIDs(
                        keyword: keyword,
                        urlSession: urlSession
                    )
                    return (index, ids)
                }
            }

            var keywordResults: [(Int, [Int])] = []
            for try await result in group {
                keywordResults.append(result)
            }

            keywordResults.sort { $0.0 < $1.0 }

            var allIDs: [Int] = []
            for (_, ids) in keywordResults {
                allIDs.append(contentsOf: ids)
            }

            let uniqueOrdered = Array(
                LinkedHashSet(allIDs)
                    .prefix(Constants.maxItems)
            )
            return uniqueOrdered
        }
    }

    private func fetchObjects(for ids: [Int]) async throws -> [MetObject] {
        try await withThrowingTaskGroup(of: MetObject?.self) { group in
            for id in ids {
                group.addTask { [urlSession] in
                    try await Self.fetchObject(
                        id: id,
                        urlSession: urlSession
                    )
                }
            }

            var objects: [MetObject] = []
            for try await object in group {
                if let object {
                    objects.append(object)
                }
            }
            let filtered = objects
                .filter { $0.primaryImageSmall != nil || $0.primaryImage != nil }
            return filtered.sorted { lhs, rhs in
                guard let lhsIndex = ids.firstIndex(of: lhs.objectID),
                      let rhsIndex = ids.firstIndex(of: rhs.objectID) else {
                    return lhs.objectID < rhs.objectID
                }
                return lhsIndex < rhsIndex
            }
        }
    }

    private static func fetchObjectIDs(keyword: String, urlSession: URLSession) async throws -> [Int] {
        var components = URLComponents(url: Constants.baseURL.appendingPathComponent("search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "q", value: keyword),
            URLQueryItem(name: "hasImages", value: "true")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("MegaRoki/1.0 (+https://collectionapi.metmuseum.org)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let searchResult = try decoder.decode(MetSearchResponse.self, from: data)
        return searchResult.objectIDs ?? []
    }

    private static func fetchObject(id: Int, urlSession: URLSession) async throws -> MetObject? {
        let url = Constants.baseURL.appendingPathComponent("objects/\(id)")

        var request = URLRequest(url: url)
        request.setValue("MegaRoki/1.0 (+https://collectionapi.metmuseum.org)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode == 404 {
            return nil
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(MetObject.self, from: data)
    }

    private static func makeItem(from object: MetObject) -> JesterItem {
        JesterItem(
            id: object.objectID,
            title: object.title ?? "Untitled",
            artist: object.artistDisplayName?.isEmpty == false ? object.artistDisplayName : nil,
            date: object.objectDate?.isEmpty == false ? object.objectDate : nil,
            medium: object.medium?.isEmpty == false ? object.medium : nil,
            department: object.department?.isEmpty == false ? object.department : nil,
            description: object.creditLine?.isEmpty == false ? object.creditLine : object.objectName,
            imageURL: URL(string: object.primaryImageSmall ?? object.primaryImage ?? ""),
            objectURL: URL(string: object.objectURL ?? "")
        )
    }
}

// MARK: - API Models

private struct MetSearchResponse: Decodable {
    let total: Int
    let objectIDs: [Int]?
}

private struct MetObject: Decodable {
    let objectID: Int
    let title: String?
    let artistDisplayName: String?
    let objectDate: String?
    let primaryImage: String?
    let primaryImageSmall: String?
    let objectURL: String?
    let medium: String?
    let department: String?
    let objectName: String?
    let creditLine: String?
}

// MARK: - Helpers

private struct LinkedHashSet<Element: Hashable>: Sequence {
    private var orderedElements: [Element] = []
    private var set: Set<Element> = []

    init<S: Sequence>(_ sequence: S) where S.Element == Element {
        for element in sequence {
            append(element)
        }
    }

    mutating func append(_ element: Element) {
        guard !set.contains(element) else { return }
        set.insert(element)
        orderedElements.append(element)
    }

    func makeIterator() -> IndexingIterator<[Element]> {
        orderedElements.makeIterator()
    }
}


