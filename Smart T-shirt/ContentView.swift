//
//  ContentView.swift
//  Smart T-shirt
//
//  Created by Shayan Hashemi on 4/27/25.
//

import SwiftUI
import Charts // Import Charts framework

struct ContentView: View {
    @StateObject private var viewModel = ECGViewModel() // Create an instance of the ViewModel

    var body: some View {
        NavigationView { // Use NavigationView for title
            VStack {
                Text("ECG Monitor")
                    .font(.largeTitle)
                    .padding(.bottom)

                // Display current backend mode
                Text("Backend Mode: \(viewModel.backendMode.capitalized)")
                    .font(.headline)
                    .padding(.bottom, 5)

                // Display Error messages if any
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.bottom, 5)
                }

                if viewModel.ecgData.isEmpty {
                    // Show different message based on mode
                    Text(viewModel.backendMode == "stopped" ? "Backend stopped. Press Start." : "Receiving data...")
                        .foregroundColor(.gray)
                } else {
                    Chart {
                        ForEach(viewModel.ecgData) { dataPoint in
                            LineMark(
                                x: .value("Time", dataPoint.time),
                                y: .value("Value", dataPoint.value)
                            )
                            .foregroundStyle(dataPoint.value > 140 ? .red : .blue) // Highlight abnormal points
                        }
                    }
                    .chartXAxis {
                        AxisMarks(preset: .automatic, values: .stride(by: .second * 2)) { _ in // Show axis marks every 2 seconds
                           AxisGridLine()
                           AxisTick()
                           AxisValueLabel(format: .dateTime.hour().minute().second(), centered: true)
                       }
                    }
                    .chartYAxisLabel("mV") // Label for Y axis
                    .frame(height: 300) // Set a fixed height for the chart
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                Spacer()

                // Control Buttons
                HStack(spacing: 15) {
                    Button("Start Normal") {
                        viewModel.setBackendMode(mode: "normal")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(viewModel.backendMode == "normal")

                    Button("Start Abnormal") {
                        viewModel.setBackendMode(mode: "abnormal")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(viewModel.backendMode == "abnormal")

                    Button("Stop") {
                        viewModel.setBackendMode(mode: "stopped")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(viewModel.backendMode == "stopped")
                }
                .padding()

            }
            .navigationTitle("Smart T-Shirt") // Set navigation bar title
            .navigationBarTitleDisplayMode(.inline)
        }
        // No need for .onAppear here as data generation starts in ViewModel's init
    }
}

#Preview {
    ContentView()
}
