// GamesTabView.swift
import SwiftUI

struct GamesTabView: View {
    @State private var selectedGame: GameType?
    @State private var showGameView = false
    
    enum GameType: String {
        case quiz = "Quiz"
        case dailyChallenge = "Daily Challenge"
        case speedMatch = "Speed Match"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(.systemIndigo).opacity(0.1), Color(.systemBackground)]),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        StatsCardView()
                            .padding(.top)
                        
                        VStack(spacing: 16) {
                            GameCardView(
                                title: "Daily Challenge",
                                subtitle: "Learn a new sign every day",
                                systemImage: "calendar.badge.clock",
                                color: .blue,
                                streakCount: 5
                            ) {
                                selectedGame = .dailyChallenge
                                showGameView = true
                            }
                            
                            GameCardView(
                                title: "Sign Language Quiz",
                                subtitle: "Practice your signing skills",
                                systemImage: "hand.wave.fill",
                                color: .purple,
                                progress: 0.7
                            ) {
                                selectedGame = .quiz
                                showGameView = true
                            }
                            
                            GameCardView(
                                title: "Speed Match",
                                subtitle: "Test your speed and accuracy",
                                systemImage: "timer",
                                color: .orange,
                                highScore: "2,450"
                            ) {
                                selectedGame = .speedMatch
                                showGameView = true
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Games")
        }
        .fullScreenCover(isPresented: $showGameView) {
            if let game = selectedGame {
                switch game {
                case .quiz:
                    QuizView()
                case .dailyChallenge:
                    DailyChallengeView()
                case .speedMatch:
                    SpeedMatchView()
                }
            }
        }
    }
}

struct StatsCardView: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Streak")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("5 Days")
                        .font(.title2)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Total Points")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("1,250")
                        .font(.title2)
                        .bold()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(radius: 2, y: 2)
    }
}

struct GameCardView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    var streakCount: Int? = nil
    var progress: Double? = nil
    var highScore: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let streak = streakCount {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(streak) day streak")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    
                    if let progress = progress {
                        ProgressView(value: progress)
                            .tint(color)
                            .padding(.top, 4)
                    }
                    
                    if let score = highScore {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("High Score: \(score)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(radius: 2, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuizView: View {
    var body: some View {
        Text("Quiz View")
    }
}

struct DailyChallengeView: View {
    var body: some View {
        Text("Daily Challenge View")
    }
}

struct SpeedMatchView: View {
    var body: some View {
        Text("Speed Match View")
    }
}

#Preview {
    GamesTabView()
}