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
                        
                        StatusHeaderView(viewModel: viewModel)
                            .padding(.horizontal)
                        
                        // Show placeholder if no data, otherwise show the chart
                        if viewModel.ecgData.isEmpty {
                            emptyDataPlaceholder
                        } else {
                            ECGChartView(viewModel: viewModel)
                        }
                        
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
                }
                .sheet(isPresented: $viewModel.showingHistoryView) {
                    HistoryView(viewModel: viewModel)
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
    
    private var exportButton: some View {
        Button(action: {
            // Ensure we get a URL from the export function
            if let url = viewModel.exportECGData() {
                exportURL = url
                isExporting = true
            }
        }) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                Text("Télécharger les Données pour le Médecin")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(exportButtonBackground)
            .foregroundColor(.white)
            .cornerRadius(14)
            .shadow(color: viewModel.ecgData.isEmpty ? Color.clear : Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)
        }
        .disabled(viewModel.ecgData.isEmpty)
        .sheet(isPresented: $isExporting, onDismiss: {
            // Clean up the URL after dismissal to prevent memory leaks
            exportURL = nil
        }) {
            if let url = exportURL {
                ShareSheet(items: [url])
                    .edgesIgnoringSafeArea(.all)
            }
        }
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

    return ContentView()
}
