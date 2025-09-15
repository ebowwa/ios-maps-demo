//
//  TutorialView.swift
//  maps-001
//
//  Interactive tutorial and onboarding
//

import SwiftUI
import MapKit

struct TutorialView: View {
    @Binding var showTutorial: Bool
    @State private var currentStep = 0
    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial = false
    @AppStorage("appMode") private var appMode: String = "wifi"
    
    let tutorialSteps: [TutorialStep] = [
        TutorialStep(
            title: "Welcome to WiFi Maps",
            description: "Find the best spots to work with reliable WiFi",
            icon: "wifi",
            features: [
                "Discover cafes, libraries, and coworking spaces",
                "Real-time WiFi speed testing",
                "Crowd-sourced quality ratings",
                "Seat-level WiFi data"
            ]
        ),
        TutorialStep(
            title: "WiFi Quality Heatmaps",
            description: "See WiFi strength at a glance",
            icon: "map.fill",
            features: [
                "Green = Excellent (50+ Mbps)",
                "Yellow = Good (25-50 Mbps)",
                "Red = Poor (<25 Mbps)",
                "Tap markers for detailed info"
            ]
        ),
        TutorialStep(
            title: "Test & Contribute",
            description: "Help build the community database",
            icon: "speedometer",
            features: [
                "Test WiFi speed at any location",
                "Rate specific seats and areas",
                "Share password hints",
                "Add amenity information"
            ]
        ),
        TutorialStep(
            title: "Filter & Search",
            description: "Find exactly what you need",
            icon: "line.3.horizontal.decrease.circle",
            features: [
                "Filter by venue type",
                "Required amenities (power, quiet, etc.)",
                "Minimum speed requirements",
                "Currently open locations"
            ]
        ),
        TutorialStep(
            title: "Development Mode",
            description: "Help us improve the app",
            icon: "hammer.fill",
            features: [
                "Switch between WiFi and Standard maps",
                "Test new features",
                "Report issues and suggestions",
                "Access debug information"
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: Double(tutorialSteps.count))
                    .progressViewStyle(.linear)
                    .tint(.blue)
                    .padding()
                
                // Content
                TabView(selection: $currentStep) {
                    ForEach(0..<tutorialSteps.count, id: \.self) { index in
                        TutorialStepView(step: tutorialSteps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentStep > 0 {
                        Button(action: previousStep) {
                            Label("Back", systemImage: "arrow.left")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if currentStep < tutorialSteps.count - 1 {
                        Button(action: nextStep) {
                            Label("Next", systemImage: "arrow.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button(action: completeTutorial) {
                            Label("Start Using App", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                
                // Skip button
                if !hasCompletedTutorial {
                    Button("Skip Tutorial") {
                        completeTutorial()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                }
            }
        }
    }
    
    func nextStep() {
        withAnimation {
            if currentStep < tutorialSteps.count - 1 {
                currentStep += 1
            }
        }
    }
    
    func previousStep() {
        withAnimation {
            if currentStep > 0 {
                currentStep -= 1
            }
        }
    }
    
    func completeTutorial() {
        hasCompletedTutorial = true
        showTutorial = false
    }
}

struct TutorialStep {
    let title: String
    let description: String
    let icon: String
    let features: [String]
}

struct TutorialStepView: View {
    let step: TutorialStep
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: step.icon)
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding()
                .background(Circle().fill(Color.blue.opacity(0.1)))
            
            // Title
            Text(step.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Description
            Text(step.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Features list
            VStack(alignment: .leading, spacing: 15) {
                ForEach(step.features, id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        
                        Text(feature)
                            .font(.subheadline)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

// Developer Helper View
struct DeveloperToolsView: View {
    @AppStorage("showDebugInfo") private var showDebugInfo = false
    @AppStorage("showTestLocations") private var showTestLocations = false
    @AppStorage("enableMockData") private var enableMockData = true
    @State private var showingFeedback = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Development Settings") {
                    Toggle("Show Debug Info", isOn: $showDebugInfo)
                    Toggle("Show Test Locations", isOn: $showTestLocations)
                    Toggle("Use Mock Data", isOn: $enableMockData)
                }
                
                Section("Features in Development") {
                    FeatureRow(title: "Indoor Floor Plans", status: .planned)
                    FeatureRow(title: "Historical WiFi Trends", status: .planned)
                    FeatureRow(title: "Favorite Spots", status: .inProgress)
                    FeatureRow(title: "Social Features", status: .planned)
                    FeatureRow(title: "Offline Maps", status: .planned)
                }
                
                Section("Testing") {
                    Button("Generate Test Data") {
                        generateTestData()
                    }
                    
                    Button("Clear All Data") {
                        clearAllData()
                    }
                    .foregroundColor(.red)
                    
                    Button("Reset Tutorial") {
                        UserDefaults.standard.set(false, forKey: "hasCompletedTutorial")
                    }
                }
                
                Section("Feedback") {
                    Button("Report Issue") {
                        showingFeedback = true
                    }
                    
                    Link("View on GitHub", destination: URL(string: "https://github.com/ebowwa/ios-maps-demo")!)
                }
            }
            .navigationTitle("Developer Tools")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingFeedback) {
                FeedbackView()
            }
        }
    }
    
    func generateTestData() {
        // Generate test WiFi spots
        print("Generating test data...")
    }
    
    func clearAllData() {
        // Clear all stored data
        print("Clearing all data...")
    }
}

struct FeatureRow: View {
    let title: String
    let status: FeatureStatus
    
    enum FeatureStatus {
        case planned, inProgress, completed
        
        var color: Color {
            switch self {
            case .planned: return .gray
            case .inProgress: return .orange
            case .completed: return .green
            }
        }
        
        var icon: String {
            switch self {
            case .planned: return "calendar"
            case .inProgress: return "hammer"
            case .completed: return "checkmark.circle"
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
            Text(title)
            Spacer()
            Text(String(describing: status).capitalized)
                .font(.caption)
                .foregroundColor(status.color)
        }
    }
}

struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss
    @State private var feedbackType = "Feature Request"
    @State private var feedbackText = ""
    
    let feedbackTypes = ["Bug Report", "Feature Request", "General Feedback", "WiFi Spot Issue"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Feedback Type") {
                    Picker("Type", selection: $feedbackType) {
                        ForEach(feedbackTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Details") {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 200)
                }
                
                Section {
                    Button("Submit Feedback") {
                        submitFeedback()
                    }
                    .disabled(feedbackText.isEmpty)
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func submitFeedback() {
        print("Feedback submitted: \(feedbackType) - \(feedbackText)")
        dismiss()
    }
}

#Preview {
    TutorialView(showTutorial: .constant(true))
}