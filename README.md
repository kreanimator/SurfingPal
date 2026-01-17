# SurfingPal 🌊

A modern, cross-platform application for checking marine weather forecasts and water sports conditions. Built with Flutter (frontend) and FastAPI (backend).

## Features

- 🏄‍♂️ **Multi-Sport Support**: Surfing, SUP, Windsurfing, Kitesurfing
- 🌊 **Real-Time Forecasts**: Marine weather data from Open-Meteo API
- 📊 **Smart Scoring**: Context-aware condition scoring with safety limits
- 🎨 **Modern UI**: Minimalistic, surf-inspired design
- 📱 **Cross-Platform**: iOS, Android, and Web support

## Project Structure

```
SurfingPal/
├── frontend/              # Flutter application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── screens/
│   │   ├── services/
│   │   └── theme/
│   └── README.md
├── backend/               # FastAPI backend
│   └── www_forecast_api/
│       └── src/
│           ├── main.py
│           ├── app.py
│           ├── scoring.py
│           └── README.md
└── README.md             # This file
```

## Quick Start

### Backend Setup

1. Navigate to backend:
   ```bash
   cd backend/www_forecast_api/src
   ```

2. Create virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Run the server:
   ```bash
   python main.py
   ```

   API will be available at `http://localhost:8000`

### Frontend Setup

1. Navigate to frontend:
   ```bash
   cd frontend
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   # For web
   flutter run -d chrome
   
   # For iOS
   flutter run -d ios
   
   # For Android
   flutter run -d android
   ```

## Documentation

- [Frontend README](frontend/README.md) - Flutter app setup and deployment
- [Backend README](backend/www_forecast_api/src/README.md) - API documentation and setup

## Technology Stack

### Frontend
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **Material Design 3** - UI components
- **Google Fonts** - Typography
- **HTTP** - API communication

### Backend
- **FastAPI** - Modern Python web framework
- **Open-Meteo API** - Marine weather data
- **Pandas** - Data processing
- **Pydantic** - Data validation

## API Endpoints

- `GET /` - API information
- `GET /health` - Health check
- `POST /api/forecast` - Get forecast with sports scores

See [Backend README](backend/www_forecast_api/src/README.md) for detailed API documentation.

## Building for Production

### Web App
```bash
cd frontend
flutter build web
```

### iOS App Store
```bash
cd frontend
flutter build ios --release
# Then archive and upload via Xcode
```

### Android Play Store
```bash
cd frontend
flutter build appbundle --release
# Upload to Google Play Console
```

## Development

### Prerequisites
- Flutter SDK 3.0+
- Python 3.10+
- Node.js (for some tooling, optional)

### Running Locally
1. Start backend: `cd backend/www_forecast_api/src && python main.py`
2. Start frontend: `cd frontend && flutter run`

### Testing
- Backend: Test via `http://localhost:8000/docs`
- Frontend: `flutter test`

## Contributing

1. Follow code style guidelines
2. Test on multiple platforms
3. Update documentation as needed
4. Ensure all tests pass

## License

[Add your license here]

## Support

For issues and questions, please open an issue on the repository.

---

Made with 🌊 for water sports enthusiasts
