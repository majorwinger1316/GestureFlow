import SwiftUI

struct DailyChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: DailyChallenge?
    
    // Sample data structure for daily challenges
    struct DailyChallenge: Identifiable {
        let id = UUID()
        let day: Int
        let date: Date
        let signWord: String
        let isUnlocked: Bool
        let isCompleted: Bool
    }
    
    // Sample challenges data
    @State private var challenges: [DailyChallenge] = {
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<30).map { day in
            let date = calendar.date(byAdding: .day, value: -day, to: today)!
            return DailyChallenge(
                day: day + 1,
                date: date,
                signWord: ["Hello", "Thank You", "Please", "Good Morning", "Friend"].randomElement()!,
                isUnlocked: day <= 0,  // Only today is unlocked
                isCompleted: day > 0   // Past days are marked as completed
            )
        }
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Stats
                HStack(spacing: 20) {
                    StatCard(title: "Current Streak", value: "7", symbol: "flame.fill", color: .orange)
                    StatCard(title: "Signs Learned", value: "24", symbol: "hand.raised.fill", color: .purple)
                }
                .padding(.horizontal)
                
                // Calendar Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                    ForEach(challenges) { challenge in
                        DayChallengeCard(challenge: challenge) {
                            if challenge.isUnlocked && !challenge.isCompleted {
                                selectedDay = challenge
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Daily Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedDay) { challenge in
            DailyChallengeDetailView(challenge: challenge)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let symbol: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: symbol)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct DayChallengeCard: View {
    let challenge: DailyChallenge
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Day indicator
                Text("Day \(challenge.day)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Status icon
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 60, height: 60)
                    
                    Group {
                        if challenge.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        } else if challenge.isUnlocked {
                            Image(systemName: "hand.raised.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Date
                Text(challenge.date.formatted(.dateTime.day().month()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if challenge.isCompleted {
            return .green
        } else if challenge.isUnlocked {
            return .blue
        } else {
            return .gray.opacity(0.5)
        }
    }
}

struct DailyChallengeDetailView: View {
    let challenge: DailyChallenge
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Sign word display
                Text(challenge.signWord)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Placeholder for AR view or video demonstration
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 300)
                    .overlay {
                        Text("AR View Placeholder")
                            .foregroundColor(.secondary)
                    }
                
                // Practice button
                Button(action: {
                    // Add practice action
                }) {
                    Text("Start Practice")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(16)
                }
            }
            .padding()
            .navigationTitle("Day \(challenge.day)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DailyChallengeView()
    }
}