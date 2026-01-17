# Quick Start Guide

Get SurfingPal up and running in 5 minutes!

## Prerequisites Check

- ✅ Python 3.10+ installed
- ✅ Flutter SDK 3.0+ installed
- ✅ Internet connection

## Step 1: Start Backend (Terminal 1)

```bash
cd backend/www_forecast_api/src

# Option A: Use startup script
./start.sh

# Option B: Manual
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

✅ Backend running at `http://localhost:8000`

## Step 2: Start Frontend (Terminal 2)

```bash
cd frontend
flutter pub get
flutter run -d chrome  # or ios, android
```

✅ App should open in your browser/emulator

## Step 3: Test the App

1. Click "Check Conditions" button
2. View forecast results for all sports
3. See scores, context data, and recommendations

## Troubleshooting

### Backend not starting?
- Check Python version: `python --version`
- Install dependencies: `pip install -r requirements.txt`
- Check port 8000 is free

### Frontend can't connect?
- Ensure backend is running
- For mobile: Update `lib/services/api_service.dart` with your computer's IP
- Check CORS settings in backend

### Flutter errors?
- Run `flutter doctor` to check setup
- Run `flutter clean && flutter pub get`

## Next Steps

- Read [Frontend README](frontend/README.md) for detailed setup
- Read [Backend README](backend/www_forecast_api/src/README.md) for API docs
- Check [DEPLOYMENT.md](DEPLOYMENT.md) for production deployment

## Need Help?

- Check the README files in each directory
- Review error messages carefully
- Ensure all prerequisites are installed

Happy surfing! 🏄‍♂️🌊
