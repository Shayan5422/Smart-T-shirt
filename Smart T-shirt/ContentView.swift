//
//  ContentView.swift
//  Smart T-shirt
//
//  Created by Shayan Hashemi on 4/27/25.
//

import SwiftUI
import Charts

// Helper View for Status and Error Messages
struct StatusHeaderView: View {
    @ObservedObject var viewModel: ECGViewModel
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: statusIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(statusColor)
                Text("Statut: \(viewModel.backendMode == "normal" ? "Normal" : (viewModel.backendMode == "abnormal" ? "Anormal" : "Arrêté"))")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(statusColor)
            }
            if let timestamp = viewModel.lastAbnormalTimestamp {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Dernière anomalie: \(timestamp, formatter: Self.dateFormatter)")
                }
                .font(.caption)
                .foregroundColor(.red)
            } else {
                Text(" ") .font(.caption)
            }
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "wifi.exclamationmark")
                    Text("Erreur: \(errorMessage)")
                }
                .font(.footnote)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
        )
    }
    
    // Computed property for status color
    private var statusColor: Color {
        switch viewModel.backendMode {
        case "normal": return .green
        case "abnormal": return .orange
        case "stopped": return .secondary
        default: return .primary
        }
    }
    private var statusIcon: String {
        switch viewModel.backendMode {
        case "normal": return "checkmark.seal.fill"
        case "abnormal": return "exclamationmark.triangle.fill"
        case "stopped": return "pause.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
}

// Helper View: Abnormal Event History List
struct AbnormalHistoryView: View {
    @ObservedObject var viewModel: ECGViewModel
    private static var historyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !viewModel.abnormalTimestamps.isEmpty {
                Text("Historique des Événements Anormaux")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.accentColor)
                    .padding(.leading, 12)
                    .padding(.top, 12)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.abnormalTimestamps.reversed(), id: \.self) { timestamp in
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .foregroundColor(.red)
                            Text(timestamp, formatter: Self.historyDateFormatter)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.red.opacity(0.05))
                        .cornerRadius(8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.3), Color.orange.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
        )
        .padding(.horizontal)
        .animation(.easeInOut, value: viewModel.abnormalTimestamps)
    }
}

// New: AI Analysis Results View
struct AIAnalysisView: View {
    @ObservedObject var viewModel: ECGViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile.fill")
                    .foregroundColor(.purple)
                Text("Analyse IA")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                Spacer()
                if viewModel.isAnalyzing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.7)
                }
            }
            .padding(.top, 4)
            .padding(.horizontal, 16)
            
            if let analysis = viewModel.currentAnalysis {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Rythme Cardiaque")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(analysis.heartRate) BPM")
                                .font(.title2.bold())
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Type de Rythme")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(analysis.rhythmType.rawValue)
                                .font(.headline)
                                .foregroundColor(analysis.rhythmType.color)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Confiance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(String(format: "%.1f%%", analysis.confidence * 100))
                                .font(.headline)
                            
                            Spacer()
                            
                            // Confidence bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.blue, .purple]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * CGFloat(analysis.confidence), height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.horizontal, 16)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recommandation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(analysis.recommendation)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground).opacity(0.8))
                )
                .padding(.horizontal, 16)
            } else if viewModel.isAIAnalysisEnabled {
                Text("En attente des données pour l'analyse...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            } else {
                Button(action: {
                    viewModel.toggleAIAnalysis()
                }) {
                    Text("Activer l'analyse IA")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .padding(.horizontal)
    }
}

// New: Stress Analysis View
struct StressAnalysisView: View {
    @ObservedObject var viewModel: ECGViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let analysis = viewModel.currentStressAnalysis {
                    Image(systemName: analysis.stressLevel.icon)
                        .foregroundColor(analysis.stressLevel.color)
                } else {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundColor(.purple)
                }
                
                Text("Analyse du Stress")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.isStressAnalysisEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                    .frame(width: 50)
            }
            .padding(.top, 4)
            .padding(.horizontal, 16)
            
            if let analysis = viewModel.currentStressAnalysis {
                VStack(spacing: 16) {
                    // Stress Level Ring
                    HStack(spacing: 25) {
                        // HRV Score
                        VStack(spacing: 2) {
                            Text("Score VFC")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(analysis.hrvScore / 100))
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 80, height: 80)
                                
                                Text("\(Int(analysis.hrvScore))")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // Respiration Rate
                        VStack(spacing: 2) {
                            Text("Respiration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .frame(width: 100, height: 60)
                                
                                VStack(spacing: 0) {
                                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                                        Text("\(analysis.respirationRate)")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.primary)
                                        
                                        Text("rpm")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 2)
                                    }
                                    
                                    if analysis.respirationRate > 18 {
                                        Text("Élevé")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    } else if analysis.respirationRate < 12 {
                                        Text("Bas")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    } else {
                                        Text("Normal")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        
                        // Stress Level
                        VStack(spacing: 2) {
                            Text("Niveau")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ZStack {
                                Circle()
                                    .fill(analysis.stressLevel.color.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: analysis.stressLevel.icon)
                                    .font(.system(size: 34))
                                    .foregroundColor(analysis.stressLevel.color)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // Recommendation
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recommandation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(analysis.recommendation)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)
                    
                    // Meditation Button (if stress is high)
                    if analysis.stressLevel == .high || analysis.stressLevel == .veryHigh {
                        Button(action: {
                            viewModel.showingMeditationView = true
                        }) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                Text("Commencer une Méditation")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                    }
                }
                .padding(.bottom, 12)
            } else if viewModel.isStressAnalysisEnabled {
                // Loading state
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    
                    Text("Analyse du niveau de stress en cours...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Enable button
                VStack {
                    Button(action: {
                        viewModel.toggleStressAnalysis()
                    }) {
                        Text("Activer l'analyse du stress")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.orange, .red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                    }
                    
                    Text("Mesure la variabilité de la fréquence cardiaque pour évaluer votre niveau de stress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .padding(.horizontal, 40)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.orange.opacity(0.5), Color.red.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .padding(.horizontal)
    }
}

// New: Meditation View
struct MeditationView: View {
    @ObservedObject var viewModel: ECGViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDuration: TimeInterval = 300 // 5 minutes default
    
    let durations: [(label: String, value: TimeInterval)] = [
        ("2 min", 120),
        ("5 min", 300),
        ("10 min", 600),
        ("15 min", 900)
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 12) {
                Text("Méditation Guidée")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.primary)
                
                Text("Prenez un moment pour vous détendre et vous recentrer")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Progress circle if meditating
            if viewModel.isMeditating {
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        .frame(width: 250, height: 250)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: viewModel.meditationProgress)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple, .pink]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 250, height: 250)
                    
                    // Time remaining
                    VStack {
                        Text(timeString(from: Int(viewModel.meditationTotalTime - viewModel.meditationTime)))
                            .font(.system(size: 60, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("restant")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 30)
                
                // Control buttons
                HStack(spacing: 50) {
                    Button(action: {
                        viewModel.stopMeditation()
                        dismiss()
                    }) {
                        VStack {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.red)
                            
                            Text("Arrêter")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                // Duration selection
                VStack(spacing: 16) {
                    Text("Durée de méditation")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach(durations, id: \.value) { duration in
                            Button(action: {
                                selectedDuration = duration.value
                            }) {
                                DurationButton(
                                    label: duration.label,
                                    isSelected: selectedDuration == duration.value
                                )
                            }
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Sound selection
                    Text("Son d'ambiance")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Picker("Son d'ambiance", selection: $viewModel.selectedAmbientSound) {
                        ForEach(ECGViewModel.AmbientSound.allCases, id: \.self) { sound in
                            Text(sound.rawValue).tag(sound)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 20)
                }
                
                // Start button
                Button(action: {
                    viewModel.meditationTotalTime = selectedDuration
                    viewModel.startMeditation(duration: selectedDuration)
                }) {
                    Text("Commencer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 30)
            }
            
            Spacer()
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// Helper view for meditation duration buttons
struct DurationButton: View {
    let label: String
    let isSelected: Bool
    
    var body: some View {
        Text(label)
            .font(.headline)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(buttonBackground)
            .cornerRadius(12)
    }
    
    private var buttonBackground: some View {
        Group {
            if isSelected {
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                Color(UIColor.secondarySystemBackground)
            }
        }
    }
}

// New: Movement Warning View
struct MovementWarningView: View {
    var body: some View {
        HStack {
            Image(systemName: "hand.raised.fill")
                .foregroundColor(.orange)
            
            Text("Mouvement détecté. Restez immobile pour des mesures précises.")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

// New: History Sessions View
struct HistoryView: View {
    @ObservedObject var viewModel: ECGViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.historicalSessions.isEmpty {
                VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text("Aucune session dans l'historique")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Les sessions seront enregistrées automatiquement lors de l'utilisation de l'application.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                } else {
                    List {
                        ForEach(viewModel.historicalSessions.sorted(by: { $0.startTime > $1.startTime })) { session in
                            VStack(alignment: .leading) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(session.formattedDate)
                                            .font(.headline)
                                        
                                        Text("Durée: \(session.formattedDuration)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        HStack {
                    Image(systemName: "heart.fill")
                                                .foregroundColor(.red)
                                            Text("\(session.averageHeartRate) BPM")
                                                .font(.headline)
                                        }
                                        
                                        if session.abnormalCount > 0 {
                                            HStack {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .foregroundColor(.orange)
                                                Text("\(session.abnormalCount) anomalies")
                                                    .font(.subheadline)
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationBarTitle("Historique des Sessions", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
                
                if !viewModel.historicalSessions.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.clearHistory()
                        }) {
                            Text("Effacer")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }
}

// New: Meditation History View
struct MeditationHistoryView: View {
    @ObservedObject var viewModel: ECGViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.meditationSessions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text("Aucune session de méditation")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Les sessions seront enregistrées automatiquement lorsque vous méditez.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                } else {
                    List {
                        ForEach(viewModel.meditationSessions.sorted(by: { $0.startTime > $1.startTime })) { session in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(session.formattedDate)
                                            .font(.headline)
                                        
                                        Text("Durée: \(session.formattedDuration)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        HStack {
                                            Image(systemName: "arrow.down")
                                                .foregroundColor(.green)
                                            Text("\(session.initialHeartRate) → \(session.finalHeartRate) BPM")
                                                .font(.footnote)
                                        }
                                        
                                        HStack {
                                            Image(systemName: "brain")
                                                .foregroundColor(.purple)
                                            Text("\(session.initialStressLevel) → \(session.finalStressLevel)")
                                                .font(.caption)
                                                .foregroundColor(.purple)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationBarTitle("Historique de Méditation", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
                
                if !viewModel.meditationSessions.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.meditationSessions = []
                            viewModel.saveMeditationSessions()
                        }) {
                            Text("Effacer")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ECGViewModel()
    @State private var isExporting = false
    @State private var exportURL: URL? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 24) {
                        logoAndTitle
                        
                        // Movement warning if needed
                        if viewModel.showMovementWarning {
                            MovementWarningView()
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        StatusHeaderView(viewModel: viewModel)
                            .padding(.horizontal)
                        
                        // Show placeholder if no data, otherwise show the chart
                        if viewModel.ecgData.isEmpty {
                            emptyDataPlaceholder
                    } else {
                        ECGChartView(viewModel: viewModel)
                        }
                        
                        // Show Stress Analysis view
                        StressAnalysisView(viewModel: viewModel)
                        
                        // Show AI Analysis if enabled or has results
                        if viewModel.isAIAnalysisEnabled || viewModel.currentAnalysis != nil {
                            AIAnalysisView(viewModel: viewModel)
                        }
                        
                        if !viewModel.abnormalTimestamps.isEmpty {
                            AbnormalHistoryView(viewModel: viewModel)
                        }
                        
                        // Toolbar instead of export button
                        toolBar
                        
                        footerView
                    }
                    .padding(.bottom)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.showMovementWarning)
                }
                .sheet(isPresented: $viewModel.showingHistoryView) {
                    HistoryView(viewModel: viewModel)
                }
                .sheet(isPresented: $viewModel.showingMeditationView) {
                    MeditationView(viewModel: viewModel)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(.accentColor)
        .sheet(isPresented: $isExporting, onDismiss: {
            // Clean up the URL after dismissal to prevent memory leaks
            exportURL = nil
        }) {
            if let url = exportURL {
                ShareSheet(items: [url])
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .alert(
            "Le rythme cardiaque anormal a duré plus de 10 secondes !",
            isPresented: $viewModel.shouldShowCallAlert
        ) {
            Button("Appeler les urgences") {
                viewModel.dismissCallAlert()
                if let url = URL(string: "tel://112") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Annuler", role: .cancel) {
                viewModel.dismissCallAlert()
            }
        } message: {
            Text("Voulez-vous appeler les urgences ?")
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color(hex: "1a1a2e") : Color(hex: "f0f2f5"),
                colorScheme == .dark ? Color(hex: "16213e") : Color(hex: "ffffff")
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var logoAndTitle: some View {
        VStack(spacing: 12) {
            heartIcon
            
            Text("Moniteur T-Shirt Intelligent")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.primary, Color.primary.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.bottom, 8)
    }
    
    private var heartIcon: some View {
        Image(systemName: "heart.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 60, height: 60)
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [Color.red, Color.pink]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
            .padding(.top, 20)
    }
    
    private var emptyDataPlaceholder: some View {
        VStack {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.bottom, 16)
            
            Text(viewModel.backendMode == "stopped" ? 
                "Backend arrêté. Utilisez le script de contrôle pour démarrer." : 
                "En attente de données...")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(emptyChartBackground)
        .padding(.horizontal)
    }
    
    private var emptyChartBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(UIColor.systemBackground).opacity(0.95))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
    }
    
    // MARK: - Tool Bar
    
    private var toolBar: some View {
        HStack(spacing: 20) {
            Button(action: {
                viewModel.showingHistoryView = true
            }) {
                VStack(spacing: 2) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                    Text("Historique")
                        .font(.system(size: 10))
                }
                .foregroundColor(.accentColor)
            }
            
            Button(action: {
                viewModel.showingMeditationView = true
            }) {
                VStack(spacing: 2) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16))
                    Text("Méditer")
                        .font(.system(size: 10))
                }
                .foregroundColor(.purple)
            }
            
            Button(action: {
                viewModel.toggleAIAnalysis()
            }) {
                VStack(spacing: 2) {
                    Image(systemName: viewModel.isAIAnalysisEnabled ? "brain.head.profile.fill" : "brain.head.profile")
                        .font(.system(size: 16))
                    Text("IA")
                        .font(.system(size: 10))
                }
                .foregroundColor(viewModel.isAIAnalysisEnabled ? .purple : .accentColor)
            }
            
            if !viewModel.ecgData.isEmpty {
                Button(action: {
                    // Ensure we get a URL from the export function
                    if let url = viewModel.exportECGData() {
                        exportURL = url
                        isExporting = true
                    }
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                        Text("Exporter")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground).opacity(0.95))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private var exportButtonBackground: some View {
        Group {
            if viewModel.ecgData.isEmpty {
                Color.gray.opacity(0.3)
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }
    
    private var footerView: some View {
        Text("© 2025 Moniteur Cardiaque")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 8)
            .padding(.bottom, 30)
    }
}

// ShareSheet for exporting files
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    let previewViewModel = ECGViewModel()
    let now = Date()
    previewViewModel.ecgData = [
        ECGDataPoint(time: now.addingTimeInterval(-4), value: 60),
        ECGDataPoint(time: now.addingTimeInterval(-3.8), value: 65),
        ECGDataPoint(time: now.addingTimeInterval(-3.6), value: 150),
        ECGDataPoint(time: now.addingTimeInterval(-3.4), value: 70),
        ECGDataPoint(time: now.addingTimeInterval(-3.2), value: 60),
        ECGDataPoint(time: now.addingTimeInterval(-3.0), value: 30), // Low value
        ECGDataPoint(time: now.addingTimeInterval(-2.8), value: 55),
        ECGDataPoint(time: now.addingTimeInterval(-2.6), value: 145),
        ECGDataPoint(time: now.addingTimeInterval(-2.4), value: 60),
        ECGDataPoint(time: now.addingTimeInterval(-2.2), value: 62),
        ECGDataPoint(time: now.addingTimeInterval(-2.0), value: 61),
    ]
    previewViewModel.backendMode = "abnormal"
    previewViewModel.lastAbnormalTimestamp = now.addingTimeInterval(-2.6)
    previewViewModel.abnormalTimestamps = [
        now.addingTimeInterval(-5), 
        now.addingTimeInterval(-3.6), 
        now.addingTimeInterval(-2.6)
    ]
    previewViewModel.errorMessage = nil
    
    // Add stress analysis for preview
    previewViewModel.currentStressAnalysis = StressAnalysis(
        timestamp: now,
        stressLevel: .high,
        hrvScore: 42.5,
        respirationRate: 22,
        recommendation: "Niveau de stress élevé détecté. Considérez une pause de 5 minutes pour méditer."
    )

    return ContentView()
}
