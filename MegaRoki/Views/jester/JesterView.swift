//
//  JesterView.swift
//  MegaRoki
//
//  Created by Роман Главацкий on 12.11.2025.
//

import SwiftUI

struct JesterView: View {
    @StateObject private var viewModel = JesterViewModel()

    var body: some View {
        ZStack {
            MainBackGradient()
                .ignoresSafeArea()
            content
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            stateContent
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Jester Chronicles")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(.goldApp)
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)

            Text("Fresh finds of jesters, fools, and court entertainers from The Met collection.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(Color(.white).opacity(0.85))
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            loadingView
        } else if let errorMessage = viewModel.errorMessage {
            errorView(message: errorMessage)
        } else if viewModel.items.isEmpty {
            emptyStateView
        } else {
            resultsView
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.goldApp)
                .scaleEffect(1.4)
            Text("Gathering the latest jester tales…")
                .multilineTextAlignment(.center)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(.white)
                .shadow(radius: 6)

            Text("Couldn’t fetch jester news right now.")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.reload()
                }
            } label: {
                MainButton(title: "Try again", height: 70)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "face.smiling")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundStyle(.white.opacity(0.9))
                .shadow(radius: 6)

            Text("No jesters spotted today.")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Try reloading a little later for more tales from The Met archives.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.reload()
                }
            } label: {
                MainButton(title: "Refresh", height: 70)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.items) { item in
                    jesterCard(for: item)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .tint(.goldApp)
                        .padding(.top, 8)
                }
            }
            .padding(.bottom, 12)
        }
    }

    private func jesterCard(for item: JesterViewModel.JesterItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageURL = item.imageURL {
                AsyncImage(url: imageURL, transaction: Transaction(animation: .spring())) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.black.opacity(0.15)
                            ProgressView()
                                .tint(.goldApp)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipped()
                            .cornerRadius(16)
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.15), lineWidth: 1)
                            }
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
            } else {
                placeholderImage
                    .frame(height: 220)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                if let artist = item.artist {
                    Text(artist)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }

                if let date = item.date {
                    Text(date)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }

                if let medium = item.medium {
                    Text(medium)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }

                if let description = item.description {
                    Text(description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                }

                if let department = item.department {
                    Text("Department: \(department)")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }

                if let objectURL = item.objectURL {
                    Link("Open on metmuseum.org", destination: objectURL)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.goldApp)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var placeholderImage: some View {
        ZStack {
            Color.black.opacity(0.25)
            Image(systemName: "person.crop.square.filled.and.at.rectangle")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(.white.opacity(0.6))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        JesterView()
    }
}
