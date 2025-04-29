import SwiftUI
import Combine
import UserNotifications
import CoreMotion
import AVFoundation

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

// New: Structure for AI Analysis Results
struct ECGAnalysisResult: Identifiable {
    let id = UUID()
    let timestamp: Date
    let heartRate: Int
    let rhythmType: RhythmType
    let confidence: Double
    let recommendation: String
    
    enum RhythmType: String, CaseIterable {
        case normal = "Rythme Normal"
        case tachycardia = "Tachycardie"
        case bradycardia = "Bradycardie"
        case irregular = "Rythme Irrégulier"
        case pvc = "Contraction Ventriculaire Prématurée"
        case afib = "Fibrillation Auriculaire"
        
        var color: Color {
            switch self {
            case .normal: return .green
            case .tachycardia, .bradycardia: return .orange
            case .irregular, .pvc, .afib: return .red
            }
        }
    }
}

// New: Structure for Stress Level Analysis
struct StressAnalysis: Identifiable {
    let id = UUID()
    let timestamp: Date
    let stressLevel: StressLevel
    let hrvScore: Double // Variability score (0-100)
    let respirationRate: Int // Breaths per minute
    let recommendation: String
    
    enum StressLevel: String, CaseIterable {
        case low = "Calme"
        case medium = "Modéré"
        case high = "Élevé"
        case veryHigh = "Très Élevé"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .blue
            case .high: return .orange
            case .veryHigh: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "leaf.fill"
            case .medium: return "wind"
            case .high: return "waveform"
            case .veryHigh: return "bolt.fill"
            }
        }
    }
}

// New: Structure for Meditation Session
struct MeditationSession: Identifiable, Codable {
    var id: UUID
    let startTime: Date
    let duration: TimeInterval
    let initialHeartRate: Int
    let finalHeartRate: Int
    let initialStressLevel: String
    let finalStressLevel: String
    
    init(startTime: Date, duration: TimeInterval, initialHeartRate: Int, finalHeartRate: Int, initialStressLevel: String, finalStressLevel: String) {
        self.id = UUID()
        self.startTime = startTime
        self.duration = duration
        self.initialHeartRate = initialHeartRate
        self.finalHeartRate = finalHeartRate
        self.initialStressLevel = initialStressLevel
        self.finalStressLevel = finalStressLevel
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
}

// New: ECG Session for Historical Records
struct ECGSession: Identifiable, Codable {
    var id: UUID
    let startTime: Date
    let endTime: Date
    let averageHeartRate: Int
    let minValue: Double
    let maxValue: Double
    let abnormalCount: Int
    let durationSeconds: Int
    
    init(startTime: Date, endTime: Date, averageHeartRate: Int, minValue: Double, maxValue: Double, abnormalCount: Int, durationSeconds: Int) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.averageHeartRate = averageHeartRate
        self.minValue = minValue
        self.maxValue = maxValue
        self.abnormalCount = abnormalCount
        self.durationSeconds = durationSeconds
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    var formattedDuration: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return "\(minutes)m \(seconds)s"
    }
}

@MainActor
class ECGViewModel: ObservableObject {
    @Published var ecgData: [ECGDataPoint] = []
    @Published var backendMode: String = "stopped" // To reflect backend state
    @Published var errorMessage: String? = nil // To show errors in UI
    @Published var lastAbnormalTimestamp: Date? = nil // Store the last abnormal event time
    @Published var abnormalTimestamps: [Date] = [] // History of abnormal events
    @Published var shouldShowCallAlert: Bool = false // New: show alert for emergency call
    @Published var hasDismissedCallAlert: Bool = false // New: track if user dismissed alert
    
    // New: AI Analysis & History features
    @Published var isAIAnalysisEnabled = false
    @Published var currentAnalysis: ECGAnalysisResult? = nil
    @Published var historicalSessions: [ECGSession] = []
    @Published var showingHistoryView = false
    @Published var isAnalyzing = false
    @Published var showingAnalysisDetails = false
    
    // New: Stress Analysis features
    @Published var isStressAnalysisEnabled = false
    @Published var currentStressAnalysis: StressAnalysis? = nil
    @Published var stressHistory: [StressAnalysis] = []
    @Published var showingStressHistory = false
    @Published var respirationRate: Int = 0
    
    // New: Meditation features
    @Published var isMeditating = false
    @Published var meditationTime: TimeInterval = 0
    @Published var meditationSessions: [MeditationSession] = []
    @Published var showingMeditationView = false
    @Published var selectedAmbientSound: AmbientSound = .none
    @Published var meditationProgress: Double = 0
    @Published var meditationTotalTime: TimeInterval = 300 // 5 minutes by default
    
    // New: Motion and Movement detection
    private let motionManager = CMMotionManager()
    @Published var isMovementDetected = false
    @Published var movementAmount: Double = 0
    @Published var showMovementWarning = false
    
    private let maxHistoryCount = 5 // Max number of history items
    private var currentSessionStartTime: Date? = nil
    private var sessionTimer: Timer? = nil
    
    // New: Meditation-related properties
    private var meditationStartTime: Date? = nil
    private var meditationStartHeartRate: Int = 0
    private var meditationStartStressLevel: String = ""
    private var meditationTimer: Timer? = nil
    private var audioPlayer: AVAudioPlayer? = nil
    
    private var fetchDataSubscription: AnyCancellable?
    private var setModeTask: AnyCancellable?
    private var statusPollingSubscription: AnyCancellable? // New for status polling
    private let backendBaseUrl = "https://smart-t-shirt.onrender.com"
    
    // New: Enum for ambient sounds during meditation
    enum AmbientSound: String, CaseIterable {
        case none = "Aucun"
        case nature = "Nature"
        case rain = "Pluie"
        case oceanWaves = "Vagues"
        case whiteNoise = "Bruit Blanc"
        
        var fileName: String? {
            switch self {
            case .none: return nil
            case .nature: return "nature_sound"
            case .rain: return "rain_sound"
            case .oceanWaves: return "ocean_sound"
            case .whiteNoise: return "white_noise"
            }
        }
    }

    // JSON Decoder configured for dates
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            // Create a formatter inside the closure to avoid Sendable issues
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = formatter.date(from: dateString) { // Use the local formatter
                return date
            } else {
                // Attempt decoding without fractional seconds as a fallback
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: dateString) {
                    return date
                } else {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
                }
            }
        }
        return decoder
    }()

    private var abnormalStartTime: Date? = nil // Track when abnormal started
    private var abnormalCheckTimer: Timer? = nil // Timer for checking abnormal duration
    private var stressAnalysisTimer: Timer? = nil // New: Timer for stress analysis

    // Observe backendMode changes
    private var backendModeObserver: AnyCancellable? = nil
    
    // New: RR intervals for HRV calculation
    private var rrIntervals: [TimeInterval] = []
    private var lastRPeak: Date? = nil

    init() {
        // Start polling the backend for data periodically
        startFetchingData()
        // Start polling the backend status periodically
        startPollingBackendStatus()
        // Observe backendMode for abnormal duration
        backendModeObserver = $backendMode.sink { [weak self] newMode in
            self?.handleAbnormalDuration()
            self?.handleSessionTracking(newMode: newMode)
        }
        
        // Load saved sessions
        loadSavedSessions()
        
        // Load saved meditation sessions
        loadSavedMeditationSessions()
        
        // Start motion detection
        startMotionDetection()
    }

    // MARK: - New Session Tracking
    
    private func handleSessionTracking(newMode: String) {
        if newMode != "stopped" {
            // Start session if not already started
            if currentSessionStartTime == nil {
                currentSessionStartTime = Date()
                // Start timer to periodically run AI analysis if enabled
                setupSessionTimer()
            }
        } else {
            // End session if we have a start time
            if let startTime = currentSessionStartTime {
                // Save the session
                saveSession(startTime: startTime)
                // Reset tracking
                currentSessionStartTime = nil
                sessionTimer?.invalidate()
                sessionTimer = nil
            }
        }
    }
    
    private func setupSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            // Capture le self faiblement pour éviter les cycles de référence
            guard let self = self else { return }
            
            // Dispatch vers le MainActor pour accéder aux propriétés isolées
            Task { @MainActor in
                // Vérifier que nous avons des données
                guard !self.ecgData.isEmpty else { return }
                
                // Lancer l'analyse si l'option est activée
                if self.isAIAnalysisEnabled {
                    self.runAIAnalysis()
                }
            }
        }
    }
    
    private func saveSession(startTime: Date) {
        let endTime = Date()
        
        // Only save if we have data
        guard !ecgData.isEmpty else { return }
        
        // Calculate session metrics
        let values = ecgData.map { $0.value }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        let durationSeconds = Int(endTime.timeIntervalSince(startTime))
        
        // Calculate heart rate (this is simplified - would normally be more complex)
        let heartRate = calculateHeartRate()
        
        // Create session and add to history
        let session = ECGSession(
            startTime: startTime,
            endTime: endTime,
            averageHeartRate: heartRate,
            minValue: minValue,
            maxValue: maxValue,
            abnormalCount: abnormalTimestamps.count,
            durationSeconds: durationSeconds
        )
        
        // Add session to our array
        historicalSessions.append(session)
        
        // Save to UserDefaults
        saveSessions()
    }
    
    private func calculateHeartRate() -> Int {
        // Simple simulation of heart rate calculation
        // In a real app, this would use a more sophisticated algorithm
        let maxHeartRate = 180
        let minHeartRate = 50
        
        if backendMode == "abnormal" {
            return Int.random(in: 110...maxHeartRate)
        } else {
            return Int.random(in: minHeartRate...100)
        }
    }
    
    // MARK: - AI Analysis
    
    func toggleAIAnalysis() {
        isAIAnalysisEnabled.toggle()
        
        if isAIAnalysisEnabled && currentSessionStartTime != nil {
            // Run initial analysis when enabled
            runAIAnalysis()
        }
    }
    
    private func runAIAnalysis() {
        // Don't analyze if we don't have data
        guard !ecgData.isEmpty else { return }
        
        // Set analyzing flag to show loading indicator
        isAnalyzing = true
        
        // Simulate AI processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Generate a simulated analysis result
            self.currentAnalysis = self.generateAnalysisResult()
            self.isAnalyzing = false
        }
    }
    
    private func generateAnalysisResult() -> ECGAnalysisResult {
        // Calculate heart rate as before
        let heartRate = calculateHeartRate()
        
        // Determine rhythm type based on backend mode and some randomness
        let rhythmTypes = ECGAnalysisResult.RhythmType.allCases
        let rhythmType: ECGAnalysisResult.RhythmType
        
        if backendMode == "abnormal" {
            // Skip normal rhythm for abnormal mode
            rhythmType = rhythmTypes.filter { $0 != .normal }.randomElement() ?? .tachycardia
        } else {
            // 80% chance of normal in normal mode
            rhythmType = Double.random(in: 0...1) < 0.8 ? .normal : rhythmTypes.randomElement() ?? .normal
        }
        
        // Generate confidence level
        let confidence = Double.random(in: 0.7...0.98)
        
        // Generate recommendation based on rhythm type
        let recommendation: String
        switch rhythmType {
        case .normal:
            recommendation = "Aucune action nécessaire. Rythme cardiaque normal."
        case .tachycardia:
            recommendation = "Rythme rapide détecté. Évitez l'exercice intense et consultez un médecin si cela persiste."
        case .bradycardia:
            recommendation = "Rythme lent détecté. Repos recommandé. Consultez un médecin si des symptômes apparaissent."
        case .irregular:
            recommendation = "Rythme irrégulier détecté. Consultez un médecin pour une évaluation."
        case .pvc:
            recommendation = "Contractions ventriculaires prématurées détectées. Surveillez et consultez un cardiologue."
        case .afib:
            recommendation = "Signes possibles de fibrillation auriculaire. Consultation médicale urgente recommandée."
        }
        
        return ECGAnalysisResult(
            timestamp: Date(),
            heartRate: heartRate,
            rhythmType: rhythmType,
            confidence: confidence,
            recommendation: recommendation
        )
    }
    
    // MARK: - Session Storage
    
    private func saveSessions() {
        if let encodedData = try? JSONEncoder().encode(historicalSessions) {
            UserDefaults.standard.set(encodedData, forKey: "ecgSessions")
        }
    }
    
    private func loadSavedSessions() {
        if let savedData = UserDefaults.standard.data(forKey: "ecgSessions"),
           let decodedSessions = try? JSONDecoder().decode([ECGSession].self, from: savedData) {
            historicalSessions = decodedSessions
        }
    }
    
    func clearHistory() {
        historicalSessions.removeAll()
        saveSessions()
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
                            let now = Date() // Get current timestamp
                            self.lastAbnormalTimestamp = now 
                            // Add to history and limit size
                            self.abnormalTimestamps.append(now)
                            if self.abnormalTimestamps.count > self.maxHistoryCount {
                                self.abnormalTimestamps.removeFirst()
                            }
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

    // Function to send the device token to the backend
    func sendDeviceTokenToBackend(token: String) async {
        guard let url = URL(string: "\(backendBaseUrl)/register_device") else {
            print("Invalid backend URL for register_device")
            // Optionally update errorMessage on the main thread if needed
            // DispatchQueue.main.async { self.errorMessage = "Internal Error: Cannot form register URL" }
            return
        }
        
        print("Sending device token to backend...")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["token": token]
        
        do {
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData
            
            // Using async/await URLSession
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("Failed to register device token with backend. Status code: \(statusCode)")
                // Optionally update errorMessage on the main thread
                // DispatchQueue.main.async { self.errorMessage = "Failed to register with backend (Code: \(statusCode))" }
                return
            }
            
            print("Successfully registered device token with backend.")
            
        } catch {
            print("Error encoding or sending device token: \(error.localizedDescription)")
            // Optionally update errorMessage on the main thread
             // DispatchQueue.main.async { self.errorMessage = "Error sending token: \(error.localizedDescription)" }
        }
    }

    // Helper struct to decode the /set_mode response
    struct SetModeResponse: Decodable {
        let status: String
        let new_mode: String
    }

    // Function to export ECG data as CSV
    func exportECGData() -> URL? {
        // Format date for CSV
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // Create CSV content with metadata header section
        var csvString = "# ECG Data Export\n"
        csvString.append("# Export Date: \(dateFormatter.string(from: Date()))\n")
        csvString.append("# Mode: \(backendMode)\n\n")
        
        // Add abnormal events section if available
        if !abnormalTimestamps.isEmpty {
            csvString.append("# Abnormal Events\n")
            for (index, timestamp) in abnormalTimestamps.enumerated() {
                csvString.append("# Event \(index + 1): \(dateFormatter.string(from: timestamp))\n")
            }
            csvString.append("\n")
        }
        
        // Add AI analysis if available
        if let analysis = currentAnalysis {
            csvString.append("# AI Analysis Results\n")
            csvString.append("# Time: \(dateFormatter.string(from: analysis.timestamp))\n")
            csvString.append("# Heart Rate: \(analysis.heartRate) BPM\n")
            csvString.append("# Rhythm Type: \(analysis.rhythmType.rawValue)\n")
            csvString.append("# Confidence: \(String(format: "%.1f%%", analysis.confidence * 100))\n")
            csvString.append("# Recommendation: \(analysis.recommendation)\n\n")
        }
        
        // Add stress analysis if available
        if let stressAnalysis = currentStressAnalysis {
            csvString.append("# Stress Analysis Results\n")
            csvString.append("# Time: \(dateFormatter.string(from: stressAnalysis.timestamp))\n")
            csvString.append("# Stress Level: \(stressAnalysis.stressLevel.rawValue)\n")
            csvString.append("# HRV Score: \(String(format: "%.1f", stressAnalysis.hrvScore))\n")
            csvString.append("# Respiration Rate: \(stressAnalysis.respirationRate) bpm\n")
            csvString.append("# Recommendation: \(stressAnalysis.recommendation)\n\n")
        }
        
        // Add data columns header
        csvString.append("Time,Value\n")
        
        // Add data rows
        for dataPoint in ecgData {
            let timeString = dateFormatter.string(from: dataPoint.time)
            csvString.append("\(timeString),\(dataPoint.value)\n")
        }
        
        // Get the temporary directory instead of documents (better for sharing)
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        
        // Create filename with current date
        let currentDate = Date()
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateFormat = "yyyyMMdd_HHmmss"
        let fileName = "ECG_Data_\(dateFormatter2.string(from: currentDate)).csv"
        
        // Create file URL in temp directory
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)
        
        // Write to file
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing CSV file: \(error)")
            return nil
        }
    }

    // Function to trigger notification (remains the same)
    private func triggerAbnormalNotification(value: Double) {
        let center = UNUserNotificationCenter.current()
        
        // Capturer la valeur pour l'utiliser dans le closure
        let capturedValue = value
        
        center.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .authorized else {
                print("Notification permission not granted.")
                return
            }
            
            // Move to main thread to avoid updating during view updates
            Task { @MainActor in
                guard let self = self else { return }
                
                let content = UNMutableNotificationContent()
                content.title = "Rythme cardiaque anormal détecté!"
                content.body = String(format: "Une lecture ECG inhabituelle de %.1f mV a été détectée.", capturedValue)
                content.sound = .default
                content.categoryIdentifier = "ECG_ABNORMAL" // Set category for notification actions
                
                // Don't set badge number as it can cause issues
                // content.badge = 1
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let requestIdentifier = "abnormalECGNotification_\(UUID().uuidString)"
                let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
                
                center.add(request) { error in
                    if let error = error {
                        print("Erreur lors de l'ajout de la notification: \(error)")
                    }
                }
            }
        }
    }

    // Poll /status every 2 seconds
    func startPollingBackendStatus() {
        statusPollingSubscription?.cancel()
        statusPollingSubscription = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchBackendStatus()
            }
    }

    // Fetch /status and update backendMode
    private func fetchBackendStatus() {
        guard let url = URL(string: "\(backendBaseUrl)/status") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let mode = json["mode"] as? String {
                    self.backendMode = mode
                }
            }
        }.resume()
    }

    // Observe backendMode changes to track abnormal duration
    private func handleAbnormalDuration() {
        abnormalCheckTimer?.invalidate()
        
        // Capturer l'état actuel pour l'utiliser dans le Timer
        let isAbnormal = backendMode == "abnormal"
        
        if isAbnormal {
            if abnormalStartTime == nil {
                abnormalStartTime = Date()
            }
            
            // Run timer logic on main thread to safely access MainActor properties
            abnormalCheckTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                // Exécuter sur le MainActor car il accède à des propriétés isolées
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    if self.backendMode != "abnormal" {
                        self.abnormalStartTime = nil
                        self.abnormalCheckTimer?.invalidate()
                        self.shouldShowCallAlert = false
                        self.hasDismissedCallAlert = false
                    } else if let start = self.abnormalStartTime, Date().timeIntervalSince(start) > 10 {
                        if !self.hasDismissedCallAlert {
                            self.shouldShowCallAlert = true
                        }
                    }
                }
            }
        } else {
            abnormalStartTime = nil
            
            // Use async to avoid updating state during view updates
            Task { @MainActor in
                shouldShowCallAlert = false
                hasDismissedCallAlert = false // Reset when mode returns to normal
            }
        }
    }

    // Call this from the alert action in ContentView
    func dismissCallAlert() {
        shouldShowCallAlert = false
        hasDismissedCallAlert = true
    }

    // MARK: - New Stress Analysis Feature
    
    func toggleStressAnalysis() {
        isStressAnalysisEnabled.toggle()
        
        if isStressAnalysisEnabled {
            startStressAnalysis()
        } else {
            stopStressAnalysis()
        }
    }
    
    private func startStressAnalysis() {
        stressAnalysisTimer?.invalidate()
        
        // Clear previous RR intervals
        rrIntervals.removeAll()
        lastRPeak = nil
        
        // Run stress analysis every 30 seconds
        stressAnalysisTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.performStressAnalysis()
            }
        }
        
        // Initial run
        Task { @MainActor in
            performStressAnalysis()
        }
    }
    
    private func stopStressAnalysis() {
        stressAnalysisTimer?.invalidate()
        stressAnalysisTimer = nil
    }
    
    private func performStressAnalysis() {
        // Need at least 30 seconds of data for meaningful HRV analysis
        guard !ecgData.isEmpty else { return }
        
        // Calculate simulated HRV
        let hrvScore = calculateHRVScore()
        
        // Determine stress level based on HRV score
        let stressLevel: StressAnalysis.StressLevel
        if hrvScore > 75 {
            stressLevel = .low
        } else if hrvScore > 50 {
            stressLevel = .medium
        } else if hrvScore > 30 {
            stressLevel = .high
        } else {
            stressLevel = .veryHigh
        }
        
        // Calculate simulated respiration rate (normal is 12-20 breaths per minute)
        let baseRespirationRate = 14
        let stressImpact = Int(max(0, 25 - (hrvScore * 0.25)))
        let calculatedRespirationRate = baseRespirationRate + stressImpact
        self.respirationRate = calculatedRespirationRate
        
        // Generate stress reduction recommendation
        let recommendation = generateStressRecommendation(stressLevel: stressLevel, hrvScore: hrvScore)
        
        // Create stress analysis result
        let analysis = StressAnalysis(
            timestamp: Date(),
            stressLevel: stressLevel,
            hrvScore: hrvScore,
            respirationRate: calculatedRespirationRate,
            recommendation: recommendation
        )
        
        // Update current analysis and add to history
        currentStressAnalysis = analysis
        stressHistory.append(analysis)
        
        // Limit history size
        if stressHistory.count > 10 {
            stressHistory.removeFirst(stressHistory.count - 10)
        }
        
        // If stress is very high, suggest meditation
        if stressLevel == .veryHigh && !isMeditating {
            // Show meditation suggestion
            showingMeditationView = true
        }
    }
    
    private func calculateHRVScore() -> Double {
        // In a real application, this would calculate time-domain and 
        // frequency-domain measures of heart rate variability
        
        // Simulate detection of R-peaks and calculation of RR intervals
        detectRPeaks()
        
        // Calculate RMSSD (Root Mean Square of Successive Differences)
        // This is one of the common HRV metrics
        if rrIntervals.count > 5 {
            // Calculate differences between successive RR intervals
            var rrDifferences: [Double] = []
            for i in 1..<rrIntervals.count {
                let diff = abs(rrIntervals[i] - rrIntervals[i-1])
                rrDifferences.append(diff)
            }
            
            // Calculate mean square of differences
            let sumOfSquares = rrDifferences.reduce(0.0) { sum, diff in
                return sum + (diff * diff)
            }
            let meanSquare = sumOfSquares / Double(rrDifferences.count)
            let rmssd = sqrt(meanSquare) * 1000 // Convert to ms
            
            // Transform RMSSD to a 0-100 scale (higher is better/calmer)
            // Typical RMSSD values range from 15-40 for adults
            let minRMSSD = 10.0
            let maxRMSSD = 50.0
            let normalizedHRV = min(100, max(0, ((rmssd - minRMSSD) / (maxRMSSD - minRMSSD)) * 100))
            
            // Factor in the app's mode (abnormal should lower the score)
            let modeMultiplier = backendMode == "abnormal" ? 0.7 : 1.0
            
            // Factor in detected movement (movement reduces accuracy)
            let movementMultiplier = isMovementDetected ? 0.8 : 1.0
            
            return normalizedHRV * modeMultiplier * movementMultiplier
        }
        
        // If we don't have enough data, simulate a score based on mode
        return backendMode == "abnormal" ? 
            Double.random(in: 20...40) : 
            Double.random(in: 50...85)
    }
    
    private func detectRPeaks() {
        // In a real application, this would use signal processing to detect R-peaks
        // Here we'll simulate this process
        
        // Sorted data points by time
        let sortedData = ecgData.sorted { $0.time < $1.time }
        
        for point in sortedData {
            // Simple R-peak detection threshold (in a real app, this would be more sophisticated)
            if point.value > 100 {
                // Check if this is a new peak (not too close to the previous one)
                if let lastPeak = lastRPeak, point.time.timeIntervalSince(lastPeak) > 0.5 {
                    // Calculate RR interval
                    let rrInterval = point.time.timeIntervalSince(lastPeak)
                    rrIntervals.append(rrInterval)
                    
                    // Keep a limited window of recent intervals
                    if rrIntervals.count > 20 {
                        rrIntervals.removeFirst()
                    }
                }
                
                // Update last peak
                lastRPeak = point.time
            }
        }
    }
    
    private func generateStressRecommendation(stressLevel: StressAnalysis.StressLevel, hrvScore: Double) -> String {
        switch stressLevel {
        case .low:
            return "Votre niveau de stress est bas. Votre cœur fonctionne de manière optimale."
        case .medium:
            return "Niveau de stress modéré. Prenez quelques respirations profondes pour vous détendre."
        case .high:
            return "Niveau de stress élevé détecté. Considérez une pause de 5 minutes pour méditer."
        case .veryHigh:
            return "Stress très élevé ! Prenez une pause, faites quelques exercices de respiration profonde et envisagez une session de méditation guidée."
        }
    }
    
    // MARK: - New Meditation Feature
    
    func startMeditation(duration: TimeInterval) {
        guard !isMeditating else { return }
        
        // Reset state
        isMeditating = true
        meditationTime = 0
        meditationProgress = 0
        meditationTotalTime = duration
        
        // Record starting values
        meditationStartTime = Date()
        meditationStartHeartRate = calculateHeartRate()
        meditationStartStressLevel = currentStressAnalysis?.stressLevel.rawValue ?? "Modéré"
        
        // Start ambient sound if selected
        if selectedAmbientSound != .none {
            playAmbientSound()
        }
        
        // Start timer
        meditationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isMeditating else { return }
                
                // Update time
                self.meditationTime += 1
                
                // Update progress
                self.meditationProgress = min(1.0, self.meditationTime / self.meditationTotalTime)
                
                // Check if meditation is complete
                if self.meditationTime >= self.meditationTotalTime {
                    self.completeMeditation()
                }
            }
        }
    }
    
    func pauseMeditation() {
        // Stop timer
        meditationTimer?.invalidate()
        
        // Pause sound
        audioPlayer?.pause()
    }
    
    func resumeMeditation() {
        // Restart timer
        meditationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isMeditating else { return }
                
                // Update time
                self.meditationTime += 1
                
                // Update progress
                self.meditationProgress = min(1.0, self.meditationTime / self.meditationTotalTime)
                
                // Check if meditation is complete
                if self.meditationTime >= self.meditationTotalTime {
                    self.completeMeditation()
                }
            }
        }
        
        // Resume sound
        audioPlayer?.play()
    }
    
    func stopMeditation() {
        // Stop timer
        meditationTimer?.invalidate()
        meditationTimer = nil
        
        // Stop sound
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Reset state
        isMeditating = false
        
        // If session was meaningful (more than 30 seconds), save it
        if meditationTime > 30, let startTime = meditationStartTime {
            let session = MeditationSession(
                startTime: startTime,
                duration: meditationTime,
                initialHeartRate: meditationStartHeartRate,
                finalHeartRate: calculateHeartRate(),
                initialStressLevel: meditationStartStressLevel,
                finalStressLevel: currentStressAnalysis?.stressLevel.rawValue ?? "Modéré"
            )
            
            // Add to history
            meditationSessions.append(session)
            
            // Save sessions
            saveMeditationSessions()
        }
    }
    
    private func completeMeditation() {
        // Vibrate device to signal completion
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Stop meditation
        stopMeditation()
    }
    
    private func playAmbientSound() {
        guard let soundName = selectedAmbientSound.fileName,
              let path = Bundle.main.path(forResource: soundName, ofType: "mp3") else {
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 0.5
            audioPlayer?.play()
        } catch {
            print("Could not play ambient sound: \(error)")
        }
    }
    
    func saveMeditationSessions() {
        if let encodedData = try? JSONEncoder().encode(meditationSessions) {
            UserDefaults.standard.set(encodedData, forKey: "meditationSessions")
        }
    }
    
    private func loadSavedMeditationSessions() {
        if let savedData = UserDefaults.standard.data(forKey: "meditationSessions"),
           let decodedSessions = try? JSONDecoder().decode([MeditationSession].self, from: savedData) {
            meditationSessions = decodedSessions
        }
    }
    
    // MARK: - Motion Detection
    
    private func startMotionDetection() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let accelerometerData = data else { return }
            
            // Calculate magnitude of acceleration
            let x = accelerometerData.acceleration.x
            let y = accelerometerData.acceleration.y
            let z = accelerometerData.acceleration.z
            
            let magnitude = sqrt(x*x + y*y + z*z)
            
            // Detect movement (1.0 is approximately no movement)
            let movementThreshold = 1.2
            let newMovementDetected = magnitude > movementThreshold
            
            // Update movement amount (0-1 scale)
            self.movementAmount = min(1.0, max(0, (magnitude - 1.0) / 0.5))
            
            // Only update if state changed
            if newMovementDetected != self.isMovementDetected {
                Task { @MainActor in
                    self.isMovementDetected = newMovementDetected
                    
                    // Show warning if significant movement during recording
                    if newMovementDetected && self.backendMode != "stopped" {
                        self.showMovementWarning = true
                        
                        // Hide warning after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            Task { @MainActor in
                                self.showMovementWarning = false
                            }
                        }
                    }
                }
            }
        }
    }

    deinit {
        // Stop the timers when the view model is deallocated
        fetchDataSubscription?.cancel()
        setModeTask?.cancel()
        statusPollingSubscription?.cancel()
        abnormalCheckTimer?.invalidate()
        backendModeObserver?.cancel()
        sessionTimer?.invalidate()
        stressAnalysisTimer?.invalidate()
        meditationTimer?.invalidate()
        motionManager.stopAccelerometerUpdates()
        audioPlayer?.stop()
    }
} 