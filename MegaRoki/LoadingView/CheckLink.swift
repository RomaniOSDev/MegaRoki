//
//  CheckLink.swift
//  BubblyBass
//
//  Created by Роман Главацкий on 26.10.2025.
//

import Foundation

struct CheckURLService {
    
    // Статический метод для проверки любого URL
    static func checkURLStatus(_ url: URL, completion: @escaping (Bool) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { _, response, error in
            if let error = error {
                print("❌ Error checking URL: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 URL Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 404 {
                    print("✅ URL доступен: \(url.absoluteString)")
                    completion(true)
                } else {
                    print("❌ URL недоступен (404): \(url.absoluteString)")
                    completion(false)
                }
            } else {
                print("❌ Invalid HTTP response")
                completion(false)
            }
        }
        task.resume()
    }
    
    // Async/Await версия
    static func checkURLStatusAsync(_ url: URL) async -> Bool {
        return await withCheckedContinuation { continuation in
            checkURLStatus(url) { isAvailable in
                continuation.resume(returning: isAvailable)
            }
        }
    }
    
    // Метод для проверки строки URL
    static func checkURLStringStatus(_ urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL string: \(urlString)")
            completion(false)
            return
        }
        checkURLStatus(url, completion: completion)
    }
    
    // Async/Await версия для строки
    static func checkURLStringStatusAsync(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL string: \(urlString)")
            return false
        }
        return await checkURLStatusAsync(url)
    }
}
