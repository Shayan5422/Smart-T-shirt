//
//  ContentView.swift
//  Smart T-shirt
//
//  Created by Shayan Hashemi on 4/27/25.
//

import SwiftUI
import Charts // Import Charts framework

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
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(statusColor)
                    .shadow(color: statusColor.opacity(0.3), radius: 4, x: 0, y: 2)
                Text("Status: \(viewModel.backendMode.capitalized)")
                    .font(.title3.bold())
                    .foregroundColor(statusColor)
            }
            .padding(.bottom, 2)
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
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(color: statusColor.opacity(0.12), radius: 10, x: 0, y: 4)
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

// Helper View for the Chart or Placeholder Text
struct ECGChartView: View {
    @ObservedObject var viewModel: ECGViewModel
    private var placeholderText: String {
        viewModel.backendMode == "stopped" ? "Backend stopped. Use control script to start." : "Waiting for data..."
    }

    var body: some View {
        Group {
            if viewModel.ecgData.isEmpty {
                Text(placeholderText)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(18)
                    .shadow(color: .blue.opacity(0.08), radius: 8, x: 0, y: 2)
                    .padding(.horizontal)
            } else {
                ActualECGChart(viewModel: viewModel)
            }
        }
    }
}

// Helper View: The actual Chart display
struct ActualECGChart: View {
    @ObservedObject var viewModel: ECGViewModel
    private let normalColor = Color.blue // Define colors
    private let abnormalColor = Color.red
    
    var body: some View {
        Chart {
            ForEach(viewModel.ecgData) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.time),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(dataPoint.value > 140 ? abnormalColor : normalColor)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXScale(domain: .automatic)
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .stride(by: .second, count: 2)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                AxisTick()
                AxisValueLabel(format: .dateTime.hour().minute().second(), centered: false, multiLabelAlignment: .trailing)
            }
        }
        .chartYAxisLabel("mV", alignment: .center)
        .chartYScale(domain: .automatic(includesZero: false))
        .frame(height: 300)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(color: .blue.opacity(0.10), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
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
        VStack {
            if !viewModel.abnormalTimestamps.isEmpty {
                Text("Recent Abnormal Events")
                    .font(.headline)
                    .foregroundColor(.accentColor)
                    .padding(.top, 4)
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.abnormalTimestamps.reversed(), id: \.self) { timestamp in
                            HStack {
                                Image(systemName: "exclamationmark.bubble.fill")
                                    .foregroundColor(.red)
                                Text(timestamp, formatter: Self.historyDateFormatter)
                                Spacer()
                            }
                            .font(.caption)
                            .padding(.vertical, 2)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 110)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .shadow(color: .red.opacity(0.08), radius: 8, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
        .animation(.easeInOut, value: viewModel.abnormalTimestamps)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ECGViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.12), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "heart.pulse.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.accentColor)
                            .shadow(color: .accentColor.opacity(0.18), radius: 8, x: 0, y: 4)
                            .padding(.top, 12)
                        Text("Smart T-Shirt Monitor")
                            .font(.largeTitle.bold())
                            .foregroundColor(.accentColor)
                            .shadow(color: .accentColor.opacity(0.10), radius: 2, x: 0, y: 1)
                        Divider().padding(.horizontal)
                        StatusHeaderView(viewModel: viewModel)
                        Divider().padding(.horizontal)
                        ECGChartView(viewModel: viewModel)
                        Divider().padding(.horizontal)
                        AbnormalHistoryView(viewModel: viewModel)
                        Spacer(minLength: 30)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
        .tint(Color.blue)
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
