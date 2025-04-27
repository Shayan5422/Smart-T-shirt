import SwiftUI
import Combine
import UserNotifications

// Updated structure to be Decodable and handle ISO8601 date string
struct ECGDataPoint: Identifiable, Decodable {
    let id = UUID() // Keep local ID for SwiftUI
    let time: Date
    let value: Double

    // Custom decoding keys if JSON keys differ (they don't in this case)
    enum CodingKeys: String, CodingKey {
        case time
        case value
    }
}

@MainActor
class ECGViewModel: ObservableObject {
    @Published var ecgData: [ECGDataPoint] = []
    @Published var backendMode: String = "stopped" // To reflect backend state
    @Published var errorMessage: String? = nil // To show errors in UI

    private var fetchDataSubscription: AnyCancellable?
    private var setModeTask: AnyCancellable?
    private let backendBaseUrl = "http://127.0.0.1:5001" // Backend URL (use localhost for now)

    // Date Formatter for ISO8601
    private static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // JSON Decoder configured for dates
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = ECGViewModel.isoDateFormatter.date(from: dateString) {
                return date
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }
        }
        return decoder
    }()

    init() {
        // Start polling the backend for data periodically
        startFetchingData()
        // Optionally fetch initial status
        // fetchBackendStatus()
    }

    // Function to start polling the /data endpoint
    func startFetchingData() {
        // Stop previous timer if any
        fetchDataSubscription?.cancel()

        // Timer to fetch data every 0.5 seconds (adjust as needed)
        fetchDataSubscription = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchData()
            }
    }

    // Function to fetch data from the backend /data endpoint
    private func fetchData() {
        guard let url = URL(string: "\(backendBaseUrl)/data") else {
            errorMessage = "Invalid backend URL"
            return
        }
        
        errorMessage = nil // Clear previous error

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    print("Error fetching data: \(error)")
                    // Consider stopping the timer or implementing backoff here
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    self.errorMessage = "Error fetching data: Invalid response from server."
                    print("Invalid response fetching data")
                    return
                }

                guard let data = data else {
                    self.errorMessage = "Error fetching data: No data received."
                    print("No data received")
                    return
                }

                do {
                    let newDataPoints = try self.jsonDecoder.decode([ECGDataPoint].self, from: data)
                    
                    // Append new data points
                    self.ecgData.append(contentsOf: newDataPoints)

                    // Keep only the last N seconds of data (e.g., 10 seconds)
                    let maxDataDuration: TimeInterval = 10.0
                    if let firstTime = self.ecgData.first?.time, 
                       let lastTime = self.ecgData.last?.time, 
                       lastTime.timeIntervalSince(firstTime) > maxDataDuration {
                        let removalCount = self.ecgData.firstIndex { $0.time.timeIntervalSince(lastTime) > -maxDataDuration } ?? 0
                        self.ecgData.removeFirst(removalCount)
                    }
                    
                    // Check for abnormal data in the newly received points
                    for point in newDataPoints {
                        if point.value > 140 { // Example threshold
                            self.triggerAbnormalNotification(value: point.value)
                        }
                    }

                } catch {
                    self.errorMessage = "Error decoding data: \(error.localizedDescription)"
                    print("Error decoding data: \(error)")
                }
            }
        }.resume()
    }
    
    // Function to set the backend's generation mode
    func setBackendMode(mode: String) {
        guard let url = URL(string: "\(backendBaseUrl)/set_mode/\(mode)") else {
             errorMessage = "Invalid backend URL for set_mode"
            return
        }
        
        errorMessage = nil
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Cancel previous task if any
        setModeTask?.cancel()
        
        setModeTask = URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                     throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: SetModeResponse.self, decoder: JSONDecoder()) // Decode response
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to set mode: \(error.localizedDescription)"
                    print("Error setting mode: \(error)")
                }
            }, receiveValue: { [weak self] response in
                print("Successfully set mode to \(response.new_mode)")
                self?.backendMode = response.new_mode // Update local state
            })
    }

    // Helper struct to decode the /set_mode response
    struct SetModeResponse: Decodable {
        let status: String
        let new_mode: String
    }

    // Function to trigger notification (remains the same)
    private func triggerAbnormalNotification(value: Double) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("Notification permission not granted.")
                return
            }
            // ... (rest of the notification logic is unchanged) ...
            let content = UNMutableNotificationContent()
            content.title = "Abnormal ECG Detected!"
            content.body = String(format: "An unusual ECG reading of %.1f mV was detected.", value)
            content.sound = .default
            content.badge = 1 // Or manage badge count appropriately

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let requestIdentifier = "abnormalECGNotification_\(UUID().uuidString)"
            let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)

            center.add(request) { error in
                if let error = error {
                    print("Error adding notification request: \(error)")
                }
            }
        }
    }

    deinit {
        // Stop the timers when the view model is deallocated
        fetchDataSubscription?.cancel()
        setModeTask?.cancel()
    }
} 