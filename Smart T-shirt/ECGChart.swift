import SwiftUI
import Charts

struct ECGChartView: View {
    @ObservedObject var viewModel: ECGViewModel
    private let normalColor = Color.blue
    private let abnormalColor = Color.red
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Électrocardiogramme")
                .font(.headline)
                .foregroundColor(.accentColor)
                .padding(.leading, 16)
            
            Chart {
                // Main line
                ForEach(viewModel.ecgData) { dataPoint in
                    LineMark(
                        x: .value("Temps", dataPoint.time),
                        y: .value("Valeur", dataPoint.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [normalColor, abnormalColor.opacity(0.7)]),
                            startPoint: .leading, endPoint: .trailing)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                // Abnormal points
                ForEach(viewModel.ecgData.filter { $0.value > 140 }) { dataPoint in
                    PointMark(
                        x: .value("Temps", dataPoint.time),
                        y: .value("Valeur", dataPoint.value)
                    )
                    .foregroundStyle(abnormalColor)
                    .symbolSize(70)
                }
                // Last value marker with annotation
                if let last = viewModel.ecgData.last {
                    PointMark(
                        x: .value("Temps", last.time),
                        y: .value("Valeur", last.value)
                    )
                    .symbolSize(70)
                    .foregroundStyle(last.value > 140 ? abnormalColor : normalColor)
                    .annotation(position: .top, alignment: .center) {
                        Text(String(format: "%.0f mV", last.value))
                            .font(.system(size: 12, weight: .bold))
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(UIColor.systemBackground).opacity(0.9))
                                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(last.value > 140 ? abnormalColor.opacity(0.6) : normalColor.opacity(0.6), lineWidth: 1.5)
                            )
                    }
                }
            }
            .chartXScale(domain: .automatic)
            .chartYAxisLabel("mV", alignment: .center)
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                        .foregroundStyle(Color.gray.opacity(0.5))
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.7))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                        .foregroundStyle(Color.gray.opacity(0.5))
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.7))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
            }
            .frame(height: 300)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground).opacity(0.95))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [normalColor.opacity(0.3), abnormalColor.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .padding(.horizontal)
        }
    }
} 