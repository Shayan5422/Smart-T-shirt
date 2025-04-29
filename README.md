# Smart T-Shirt Monitor

<p align="center">
  <img src="Smart%20T-shirt/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" alt="Smart T-Shirt Logo" width="200" height="200">
</p>

**Smart T-Shirt Monitor** is an advanced iOS application that connects with smart clothing to monitor heart activity, detect abnormalities, analyze stress levels, and provide relaxation tools for overall cardiac wellness.

## 🔍 Features

### Heart Monitoring
- **Real-time ECG Visualization**: View electrocardiogram data in real-time with smooth animations
- **Abnormality Detection**: Automatic detection of irregular heart rhythms with alert system
- **Emergency Calling**: One-tap emergency calls when prolonged abnormalities are detected
- **Data History**: Comprehensive storage of all ECG sessions

### Advanced Analysis
- **AI-Powered ECG Assessment**: Analyzes heart rhythm patterns and provides diagnosis suggestions
- **Heart Rate Variability**: Calculates HRV scores to measure autonomic nervous system balance
- **Stress Level Monitoring**: Tracks and categorizes stress levels with visual indicators
- **Respiration Rate Calculation**: Estimates breathing rate based on heart data

### Wellness Tools
- **Guided Meditation**: Timed meditation sessions with progress tracking
- **Ambient Sounds**: Selection of calming soundscapes for relaxation
- **Motion Detection**: Alerts when movement might affect reading accuracy
- **Stress Reduction Recommendations**: Personalized suggestions based on stress levels

### Medical Integration
- **Medical Export**: Export all data in CSV format for healthcare professionals
- **Session History**: Track progress over time with detailed history views
- **Comprehensive Reports**: Generate detailed reports including ECG, stress, and meditation data

## 💡 How It Works

The Smart T-Shirt Monitor operates within a comprehensive system architecture:

1. **Data Collection**: ECG data is captured by sensors embedded in the smart t-shirt
2. **Data Transmission**: Sensor data is transmitted to the backend server
3. **AI Analysis**: The backend processes the ECG data through artificial intelligence models to:
   - Determine if the heart rhythm is normal or abnormal
   - Identify specific cardiac conditions when present
   - Calculate stress levels and HRV scores
4. **iOS App Display**: Results and analysis are sent to the iOS app for real-time visualization
5. **Alert System**: Abnormal patterns trigger alerts on the app with emergency calling options
6. **Data Storage**: All sessions are stored for historical analysis and medical review

This architecture enables detailed medical-grade analysis while maintaining a user-friendly interface for everyday health monitoring.

## 🚀 Installation

### Requirements
- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

### Backend Setup
The application requires a backend server for streaming ECG data:

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install required dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Start the backend server:
   ```bash
   python main.py
   ```

### iOS App Setup
1. Open `Smart T-shirt.xcodeproj` in Xcode
2. Select your deployment target (device or simulator)
3. Build and run the application

## 🏗️ Project Structure

```
Smart T-shirt/
├── Smart_T_shirtApp.swift     # Main app entry point
├── ContentView.swift          # Main UI view
├── ECGViewModel.swift         # Core data handling and business logic
├── ECGChart.swift             # ECG visualization component
├── Resources/                 # Audio resources for meditation
└── Assets.xcassets/           # Images and app icons
```

## 📱 Usage

1. **Start Monitoring**: Launch the app and ensure your Smart T-shirt is properly worn
2. **View ECG Data**: The main screen shows real-time ECG data
3. **Enable AI Analysis**: Toggle the AI analysis feature for advanced rhythm interpretation
4. **Activate Stress Monitoring**: Enable stress analysis for HRV and stress level tracking
5. **Meditation**: Access guided meditation sessions through the meditation button
6. **Export Data**: Share your ECG, stress, and session data with healthcare providers

## 🔌 Smart T-Shirt Hardware

For optimal performance, this application is designed to work with our Smart T-Shirt hardware featuring:

- Embedded ECG electrodes
- Bluetooth Low Energy connectivity
- Long-lasting battery life
- Machine washable design
- Various sizes available

*Note: This application can be used in demo mode without hardware.*

## 🔧 Customization

The application features several customizable parameters:

```swift
// Abnormal heart rate threshold
if point.value > 140 { // Adjust threshold as needed
    // Abnormal heart activity detected
}

// Meditation durations
let durations: [(label: String, value: TimeInterval)] = [
    ("2 min", 120),
    ("5 min", 300),
    ("10 min", 600),
    ("15 min", 900)
]

// HRV score thresholds
if hrvScore > 75 {
    stressLevel = .low
} else if hrvScore > 50 {
    stressLevel = .medium
} else if hrvScore > 30 {
    stressLevel = .high
} else {
    stressLevel = .veryHigh
}
```

## 🌐 Backend API

The backend server exposes the following endpoints:

- **GET /data**: Returns the latest ECG data points
- **GET /status**: Returns the current backend status and mode
- **POST /set_mode/{mode}**: Sets the backend mode (normal, abnormal, stopped)
- **POST /register_device**: Registers a device for notifications

### Backend AI Models

The backend incorporates advanced AI models for ECG analysis:

- **Rhythm Classification**: Detection of normal rhythm vs. various arrhythmias
- **Disease Identification**: Diagnosis of specific cardiac conditions
- **Anomaly Detection**: Identification of unexpected patterns in ECG waveforms
- **Stress Analysis**: Calculation of stress levels from heart rate variability

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and bug reports, please file an issue on our GitHub repository or contact support@smarttshirt.com.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📋 Roadmap

- Apple Watch companion app
- Android support
- Integration with Apple Health
- Multi-user profiles
- Cloud-based data storage with physician access portal 