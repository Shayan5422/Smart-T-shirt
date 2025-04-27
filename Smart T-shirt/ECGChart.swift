import SwiftUI
import Charts

struct ECGChartView: View {
    @ObservedObject var viewModel: ECGViewModel
    private let normalColor = Color.accentColor
    private let abnormalColor = Color.red
    
    var body: some View {
        Chart {
            // Main line
            ForEach(viewModel.ecgData) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.time),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [normalColor, abnormalColor.opacity(0.7)]),
                        startPoint: .leading, endPoint: .trailing)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }
            // Abnormal points
            ForEach(viewModel.ecgData.filter { $0.value > 140 }) { dataPoint in
                PointMark(
                    x: .value("Time", dataPoint.time),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(abnormalColor)
                .symbolSize(60)
            }
            // Last value marker with annotation
            if let last = viewModel.ecgData.last {
                PointMark(
                    x: .value("Time", last.time),
                    y: .value("Value", last.value)
                )
                .symbolSize(60)
                .foregroundStyle(normalColor)
                .annotation(position: .top, alignment: .center) {
                    Text(String(format: "%.0f mV", last.value))
                        .font(.caption2.weight(.bold))
                        .padding(4)
                        .background(Color(.systemBackground).opacity(0.85))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(normalColor.opacity(0.5), lineWidth: 1)
                        )
                        .shadow(radius: 1, y: 1)
                }
            }
        }
        .chartXScale(domain: .automatic)
        .chartYAxisLabel("mV", alignment: .center)
        .chartYScale(domain: .automatic(includesZero: false))
        .frame(height: 300)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .padding(.horizontal)
    }
} 