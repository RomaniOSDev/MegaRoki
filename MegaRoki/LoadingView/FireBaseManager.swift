//
//  FireBaseManager.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 24.11.2025.
//

import Foundation
import Firebase
import FirebaseDatabase

final class FireBaseManager {
    static let shared = FireBaseManager()
    
    private let databaseRef: DatabaseReference
    
    private init() {
        FirebaseApp.configure()
        
        // Указываем правильный URL для вашей базы данных в Europe West
        Database.database().isPersistenceEnabled = false
        self.databaseRef = Database.database(url: "https://mega-roki-default-rtdb.europe-west1.firebasedatabase.app").reference()
        
        print("FireBaseManager init with Europe West database")
    }
    
    // MARK: - Специальные методы для ваших данных
    
    func fetchTopRates() async throws -> String {
        do {
            let topRates: TopRates = try await self.fetchDataAsync(from: "top-rates")
            return topRates.topRates
        } catch {
            print("❌ Ошибка получения top-rates: \(error)")
            throw error
        }
    }
    
    // Альтернативный упрощенный метод
    func fetchTopRatesURL() async throws -> String {
        let ref = databaseRef.child("top-rates")
        
        return try await withCheckedThrowingContinuation { continuation in
            ref.observeSingleEvent(of: .value) { snapshot in
                if let urlString = snapshot.value as? String {
                    print("✅ Получен URL из Firebase: \(urlString)")
                    continuation.resume(returning: urlString)
                } else {
                    let error = NSError(
                        domain: "FireBaseManager",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "URL не найден в базе данных"]
                    )
                    print("❌ Ошибка: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Basic Methods
    
    private func fetchData<T: Decodable>(from path: String, completion: @escaping (Result<T, Error>) -> Void) {
        let ref = databaseRef.child(path)
        
        print("🔍 Запрос к Firebase по пути: \(path)")
        
        ref.observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                let error = NSError(domain: "FireBaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Данные не найдены по пути: \(path)"])
                print("❌ Данные не найдены: \(error)")
                completion(.failure(error))
                return
            }
            
            print("📦 Получены сырые данные: \(value)")
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: value)
                let decoder = JSONDecoder()
                let decodedObject = try decoder.decode(T.self, from: jsonData)
                print("✅ Данные успешно декодированы: \(decodedObject)")
                completion(.success(decodedObject))
            } catch {
                print("❌ Ошибка декодирования: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Async/Await методы
    
    func fetchDataAsync<T: Decodable>(from path: String) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            fetchData(from: path) { (result: Result<T, Error>) in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - Тестовый метод для проверки подключения
    func testConnection() async -> Bool {
        do {
            let url: String = try await fetchTopRatesURL()
            print("✅ Firebase подключен корректно. Получен URL: \(url)")
            return true
        } catch {
            print("❌ Ошибка подключения к Firebase: \(error)")
            return false
        }
    }
}

// MARK: - Модель данных

struct TopRates: Codable {
    let topRates: String
    
    enum CodingKeys: String, CodingKey {
        case topRates = "top-rates"
    }
}

// MARK: - Extension для доступа к reference

extension FireBaseManager {
    var database: DatabaseReference {
        return databaseRef
    }
}
