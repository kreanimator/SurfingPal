# SurfingPal Frontend

A modern, minimalistic Flutter application for checking marine weather forecasts for water sports enthusiasts.

## Features

- 🏄‍♂️ Beautiful, surf-inspired UI design
- 🌊 Real-time forecast data for multiple water sports
- 📱 Cross-platform support (iOS, Android, Web)
- 🎨 Modern Material Design 3 with custom surf theme
- ⚡ Fast and responsive user experience

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.0.0 or higher)
  - Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
  - Verify installation: `flutter doctor`

- **Dart SDK** (comes with Flutter)

- **IDE** (optional but recommended):
  - Android Studio / IntelliJ IDEA with Flutter plugin
  - VS Code with Flutter extension

- **Backend API** running (see backend README)

## Installation

1. **Clone the repository** (if not already done):
   ```bash
   cd /path/to/SurfingPal
   ```

2. **Navigate to frontend directory**:
   ```bash
   cd frontend
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

## Running the Application

### Local Development

1. **Start the backend API** (see backend README):
   ```bash
   # In a separate terminal
   cd ../backend/www_forecast_api/src
   python main.py
   ```
   The API should be running on `http://localhost:8000`

2. **Update API URL** (if needed):
   - Edit `lib/services/api_service.dart`
   - Change `baseUrl` if your backend is running on a different host/port

3. **Run the Flutter app**:

   **For Web:**
   ```bash
   flutter run -d chrome
   ```

   **For iOS Simulator:**
   ```bash
   flutter run -d ios
   ```

   **For Android Emulator:**
   ```bash
   flutter run -d android
   ```

   **For a specific device:**
   ```bash
   flutter devices  # List available devices
   flutter run -d <device-id>
   ```

### Hot Reload

While the app is running:
- Press `r` in the terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

## Project Structure

```
frontend/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/
│   │   └── forecast_data.dart   # Data models
│   ├── screens/
│   │   ├── home_screen.dart      # Home screen with main button
│   │   └── results_screen.dart  # Results display screen
│   ├── services/
│   │   └── api_service.dart     # API communication
│   └── theme/
│       └── app_theme.dart        # App theme and colors
├── assets/                       # Images, icons, etc.
├── pubspec.yaml                  # Dependencies and config
└── README.md                     # This file
```

## Building for Production

### Web App

```bash
flutter build web
```

Output will be in `build/web/`. Deploy this folder to any static hosting service.

### iOS App Store

1. **Configure iOS settings**:
   ```bash
   # Edit ios/Runner.xcodeproj or use Xcode
   ```

2. **Build for release**:
   ```bash
   flutter build ios --release
   ```

3. **Archive and upload** via Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Product → Archive
   - Distribute App → App Store Connect

### Android Play Store

1. **Configure Android settings**:
   - Edit `android/app/build.gradle`
   - Update `applicationId`, `versionCode`, `versionName`

2. **Generate signing key** (first time only):
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

3. **Configure signing** in `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=<path-to-keystore>
   ```

4. **Build APK**:
   ```bash
   flutter build apk --release
   ```

5. **Build App Bundle** (recommended for Play Store):
   ```bash
   flutter build appbundle --release
   ```

6. **Upload** `build/app/outputs/bundle/release/app-release.aab` to Google Play Console

## Configuration

### API Endpoint

Edit `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://your-api-url:8000';
```

For production, use your deployed backend URL.

### Theme Customization

Edit `lib/theme/app_theme.dart` to customize colors, fonts, and styling.

## Troubleshooting

### Common Issues

1. **"Connection refused" error**:
   - Ensure backend is running on `http://localhost:8000`
   - Check firewall settings
   - For mobile devices, use your computer's IP address instead of `localhost`

2. **Dependencies not installing**:
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Build errors**:
   ```bash
   flutter doctor -v  # Check for issues
   flutter clean
   flutter pub get
   ```

4. **iOS build issues**:
   - Ensure Xcode is installed and updated
   - Run `pod install` in `ios/` directory
   - Open Xcode and resolve any signing issues

5. **Android build issues**:
   - Ensure Android SDK is properly installed
   - Check `android/local.properties` has correct SDK path
   - Ensure `minSdkVersion` in `android/app/build.gradle` is compatible

## Development Tips

- Use `flutter analyze` to check for code issues
- Use `flutter test` to run tests
- Enable Flutter DevTools for debugging: `flutter pub global activate devtools`

## Platform-Specific Notes

### Web
- CORS must be enabled on the backend (already configured)
- Some features may behave differently in web browsers

### iOS
- Requires macOS and Xcode for building
- Minimum iOS version: 12.0 (configurable in `ios/Podfile`)

### Android
- Minimum SDK version: 21 (Android 5.0)
- Target SDK version: 33+ (configurable in `android/app/build.gradle`)

## Contributing

1. Follow Flutter style guide
2. Use meaningful variable names
3. Add comments for complex logic
4. Test on multiple platforms before submitting

## License

See main project LICENSE file.
