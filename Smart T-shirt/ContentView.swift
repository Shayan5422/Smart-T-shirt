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
                Text("Status: \(viewModel.backendMode.capitalized)")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(statusColor)
            }
            if let timestamp = viewModel.lastAbnormalTimestamp {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Last Abnormal: \(timestamp, formatter: Self.dateFormatter)")
                }
                .font(.caption)
                .foregroundColor(.red)
            } else {
                Text(" ") .font(.caption)
            }
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "wifi.exclamationmark")
                    Text("Error: \(errorMessage)")
                }
                .font(.footnote)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator), lineWidth: 1)
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
                Text("Recent Abnormal Events")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.accentColor)
                    .padding(.leading, 8)
                    .padding(.top, 4)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(viewModel.abnormalTimestamps.reversed(), id: \.self) { timestamp in
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .foregroundColor(.red)
                            Text(timestamp, formatter: Self.historyDateFormatter)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 2)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .padding(.horizontal)
        .animation(.easeInOut, value: viewModel.abnormalTimestamps)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ECGViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.accentColor)
                        .padding(.top, 16)
                    Text("Smart T-Shirt Monitor")
                        .font(.title.weight(.bold))
                        .foregroundColor(.primary)
                        .padding(.bottom, 2)
                    StatusHeaderView(viewModel: viewModel)
                    // Show placeholder if no data, otherwise show the chart
                    if viewModel.ecgData.isEmpty {
                        Text(viewModel.backendMode == "stopped" ? "Backend stopped. Use control script to start." : "Waiting for data...")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                            .padding(.horizontal)
                    } else {
                        ECGChartView(viewModel: viewModel)
                    }
                    AbnormalHistoryView(viewModel: viewModel)
                    Spacer(minLength: 30)
                }
                .padding(.bottom)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(.accentColor)
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
