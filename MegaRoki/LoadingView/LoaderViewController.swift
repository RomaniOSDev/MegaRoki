//
//  TaskDetailView.swift
//  BubblyBass
//
//  Created by Роман Главацкий on 26.10.2025.
//

import UIKit
import SwiftUI

class LoadingSplash: UIViewController {

    let loadingLabel = UILabel()
    let loadingImage = UIImageView()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // Добавляем свойство для хранения Firebase URL
    private var firebaseURL: String?
    
    private var didStartFlow = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didStartFlow else { return }
        didStartFlow = true
        setupFlow()
    }

    private func setupUI() {
        print("start setupUI")
        view.addSubview(loadingImage)
        loadingImage.image = UIImage(resource: .welcomIcin)
        loadingImage.contentMode = .scaleAspectFit
        loadingImage.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(activityIndicator)
        
        loadingImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingImage.topAnchor.constraint(equalTo: view.topAnchor),
            loadingImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupFlow() {
        activityIndicator.startAnimating()

        // Загружаем Firebase URL параллельно с ожиданием AppsFlyer
        loadFirebaseURL()
        
        if let savedURL = UserDefaults.standard.string(forKey: "finalAppsflyerURL") {
            print("Using existing AppsFlyer data")
            appsFlyerDataReady()
        } else {
            print("⌛ Waiting for AppsFlyer data...")

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appsFlyerDataReady),
                name: Notification.Name("AppsFlyerDataReceived"),
                object: nil
            )

            // Таймаут на случай, если данные так и не придут
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if UserDefaults.standard.string(forKey: "finalAppsflyerURL") == nil {
                    print("Timeout waiting for AppsFlyer. Proceeding with fallback.")
                    self.appsFlyerDataReady()
                }
            }
        }
    }
    
    // MARK: - Firebase Integration
    
    private func loadFirebaseURL() {
        Task {
            do {
                print("🔄 Загружаем URL из Firebase...")
                let urlString = try await FireBaseManager.shared.fetchTopRatesURL()
                print("✅ Firebase URL загружен: \(urlString)")
                self.firebaseURL = urlString
                
                // Проверяем подключение к Firebase
                let isConnected = await FireBaseManager.shared.testConnection()
                print("Статус подключения Firebase: \(isConnected ? "✅ Успешно" : "❌ Ошибка")")
                
            } catch {
                print("❌ Ошибка загрузки Firebase URL: \(error.localizedDescription)")
                self.firebaseURL = nil
            }
        }
    }

    @objc private func appsFlyerDataReady() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("AppsFlyerDataReceived"), object: nil)
        proceedWithFlow()
    }
    
    private func proceedWithFlow() {
        // Сначала проверяем Firebase URL, если он загружен
        if let firebaseURL = firebaseURL, let url = URL(string: firebaseURL) {
            checkAndProcessFirebaseURL(url)
        } else {
            // Если Firebase URL не загружен, используем старую логику
            showSwiftUIContent()
        }
    }
    
    private func checkAndProcessFirebaseURL(_ url: URL) {
        print("🔍 Проверяем Firebase URL: \(url.absoluteString)")
        
        CheckURLService.checkURLStatus(url) { [weak self] is200 in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if is200 {
                    print("✅ Firebase URL доступен, открываем WebView")
                    self.openWebViewWithFirebaseURL(url)
                } else {
                    print("❌ Firebase URL недоступен, проверяем резервный URL")
                    self.showSwiftUIContent()
                }
            }
        }
    }
    
    private func openWebViewWithFirebaseURL(_ url: URL) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.restrictRotation = .all
        }
        activityIndicator.stopAnimating()
        
        // Используем Firebase URL как базовую ссылку и добавляем AppsFlyer параметры
        let finalURL = self.generateTrackingLinkWithFirebase(baseURL: url.absoluteString)
        let vc = WebviewVC(url: URL(string: finalURL)!)
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    
    private func showSwiftUIContent() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.restrictRotation = .portrait
        }
        activityIndicator.stopAnimating()
        let swiftUIView = ContentView()
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.modalPresentationStyle = .fullScreen
        self.present(hostingController, animated: true)
    }
    
    // Генерация ссылки с Firebase URL как базой
    func generateTrackingLinkWithFirebase(baseURL: String) -> String {
        if let savedURL = UserDefaults.standard.string(forKey: "finalAppsflyerURL") {
            // Если есть AppsFlyer параметры, добавляем их к Firebase URL
            let separator = baseURL.contains("?") ? "&" : "?"
            let full = baseURL + separator + savedURL
            print("Generated tracking link with Firebase: \(full)")
            return full
        } else {
            // Если нет AppsFlyer параметров, используем чистый Firebase URL
            print("AppsFlyer data not available, using Firebase URL only: \(baseURL)")
            return baseURL
        }
    }
    
}
