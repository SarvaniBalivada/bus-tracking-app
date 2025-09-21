# OmniTrack

OmniTrack - A comprehensive Flutter-based bus tracking system with real-time location tracking, admin management, and user-friendly interface.

## Features

### Admin Features
- **Bus Management**: Add, edit, and delete bus information
- **Station Management**: Manage bus stations and stops
- **Real-time Monitoring**: Monitor all buses on a map with live updates
- **Driver Management**: Manage driver details and assignments
- **Emergency Alerts**: Receive and respond to emergency situations

### User Features
- **Real-time Bus Tracking**: Track buses on Google Maps with live location updates
- **Route Information**: View bus routes, stops, and estimated arrival times
- **Bus Search**: Find buses by number or route
- **Passenger Count**: View current passenger occupancy
- **Offline Support**: Limited functionality when offline

### NodeMCU Integration
- **Real-time Data**: ESP32 devices send live location, passenger count, and bus status
- **Emergency Detection**: Automatic emergency alert system
- **Speed Monitoring**: Track bus speed for safety compliance
- **Passenger Counting**: YOLO v8 based passenger detection via camera

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Maps**: Google Maps API
- **Real-time Communication**: Firebase Realtime Database
- **IoT Integration**: NodeMCU ESP32 with WiFi
- **Computer Vision**: YOLO v8 for passenger counting

## Prerequisites

Before running this app, make sure you have:

1. **Flutter SDK** (>=3.10.0)
2. **Android Studio** with Flutter plugin
3. **Firebase Account** and project setup
4. **Google Maps API Key**
5. **NodeMCU ESP32 Development Board**
6. **OV2640 Camera Module**
7. **NEO-6M GPS Module**

## Installation & Setup

### 1. Install Flutter
```bash
# Download Flutter SDK from https://docs.flutter.dev/get-started/install
# Add flutter/bin to your PATH

# Verify installation
flutter doctor
```

### 2. Clone and Setup Project
```bash
# Navigate to your desired directory
cd C:\Users\aeip3\OneDrive\Desktop\sih

# The project is already created in bus_tracking_app folder
cd bus_tracking_app

# Get dependencies
flutter pub get
```

### 3. Firebase Setup
1. Create a new Firebase project at https://console.firebase.google.com
2. Enable Authentication (Email/Password)
3. Create Firestore Database
4. Download `google-services.json` for Android
5. Place it in `android/app/google-services.json`
6. Update `firebase_options.dart` with your project configuration

### 4. Google Maps Setup
1. Get Google Maps API Key from Google Cloud Console
2. Enable Maps SDK for Android/iOS
3. Replace `YOUR_GOOGLE_MAPS_API_KEY` in `android/app/src/main/AndroidManifest.xml`

### 5. Run the Application
```bash
# For Android
flutter run

# For specific device
flutter devices
flutter run -d <device-id>
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── bus_model.dart
│   └── station_model.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   └── bus_provider.dart
├── screens/                  # UI screens
│   ├── auth/
│   ├── admin/
│   └── user/
├── utils/
│   └── constants.dart        # App constants
└── firebase_options.dart     # Firebase configuration
```

## Hardware Setup (NodeMCU)

### Components Required:
- NodeMCU ESP32 Development Board
- OV2640 Camera Module (2MP)
- NEO-6M GPS Module
- Connecting wires
- Power supply (5V)

### Connections:
```
ESP32        | Component
-------------|------------
GPIO 21      | GPS Module (SDA)
GPIO 22      | GPS Module (SCL)
GPIO 0       | Camera (D0)
GPIO 1       | Camera (D1)
... (Camera connection details)
```

### Arduino Code Features:
- WiFi connectivity
- GPS location tracking
- Camera-based passenger counting (YOLO v8)
- Real-time data transmission to Firebase
- Emergency alert system
- Speed monitoring

## API Endpoints

The app uses Firebase Firestore with the following collections:

- `/users` - User authentication and profiles
- `/buses` - Bus information and real-time data
- `/stations` - Bus station/stop information
- `/trips` - Trip schedules and tracking
- `/real_time_data` - Live bus tracking data

## Usage

### For Admins:
1. Register with admin role
2. Add bus information (bus number, driver details, device ID)
3. Add station information
4. Monitor buses in real-time
5. Respond to emergency alerts

### For Users:
1. Register as a regular user
2. View available buses
3. Track buses on map
4. Get real-time updates on bus location and passenger count

## Development

### Adding New Features:
1. Create models in `lib/models/`
2. Add providers in `lib/providers/`
3. Create UI screens in `lib/screens/`
4. Update Firebase rules as needed

### Testing:
```bash
# Run tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## Deployment

### Android:
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### iOS:
```bash
# Build iOS
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test
4. Submit pull request

## Security Notes

- Never commit API keys to version control
- Use environment variables for sensitive data
- Implement proper Firebase security rules
- Validate all user inputs
- Use HTTPS for all communications

## Troubleshooting

### Common Issues:
1. **Flutter not found**: Add Flutter to PATH
2. **Firebase connection issues**: Check google-services.json
3. **Maps not loading**: Verify API key and billing
4. **Location permissions**: Enable in device settings

### Debug Commands:
```bash
flutter doctor -v
flutter clean && flutter pub get
flutter logs
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Contact the development team
- Check Flutter documentation
- Firebase documentation