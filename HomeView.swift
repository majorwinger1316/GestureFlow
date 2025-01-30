import SwiftUI

struct HomeView: View {
    @State private var progress: CGFloat = 0.72
    @State private var streakDays: Int = 5
    @State private var isAnimating = false
    @State private var isProfilePresented = false
    @State private var selectedTab = 0
    
    let categories = [
        ("Greetings", 0.8, "hand.wave.fill"),
        ("Numbers", 0.6, "hand.point.up.fill"),
        ("Family", 0.4, "person.2.fill"),
        ("Colors", 0.7, "paintpalette.fill"),
        ("Food", 0.5, "fork.knife"),
        ("Animals", 0.3, "pawprint.fill")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Section
                    welcomeSection
                    
                    // Daily Streak Card
                    streakCard
                        .transition(.scale)
                    
                    // Progress Section
                    Text("Your Progress")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    progressGrid
                    
                    // Continue Learning Section
                    Text("Continue Learning")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    learningSection
                    
                    // Games Section
                    gamesSection
                }
                .padding(.top)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("GestureFlow")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isProfilePresented.toggle() }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.purple)
                    }
                }
            }
            .sheet(isPresented: $isProfilePresented) {
                ProfileView(isPresented: $isProfilePresented, streak: $streakDays)
            }
        }
    }
    
    // MARK: - Components
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Ready to continue your learning journey?")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    private var streakCard: some View {
        VStack {
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(streakDays) Day Streak!")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("Keep up the great work!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
    
    private var progressGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(categories, id: \.0) { category in
                ProgressCard(
                    title: category.0,
                    progress: category.1,
                    symbol: category.2
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var learningSection: some View {
        VStack(spacing: 16) {
            ForEach(0..<3) { index in
                NavigationLink(destination: LessonView()) {
                    LessonCard(
                        title: "Basic Signs - Part \(index + 1)",
                        progress: CGFloat(index + 1) * 0.33,
                        symbol: "hand.point.up.fill"
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var gamesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Games")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink(destination: GamesTabView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                }
            }
            
            NavigationLink(destination: DailyChallengeView()) {
                GameCard(
                    title: "Daily Challenge",
                    symbol: "calendar.badge.clock",
                    description: "Master one new sign every day",
                    gradient: [Color.blue, Color.blue.opacity(0.7)]
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct ProgressCard: View {
    let title: String
    let progress: CGFloat
    let symbol: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.purple)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.headline)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct LessonCard: View {
    let title: String
    let progress: CGFloat
    let symbol: String
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                
                Text("\(Int(progress * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}