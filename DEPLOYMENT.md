# Deployment Guide

This guide covers deploying SurfingPal to production environments.

## Backend Deployment

### Option 1: Docker (Recommended)

1. **Create Dockerfile** in `backend/www_forecast_api/src/`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

2. **Build and run**:
```bash
cd backend/www_forecast_api/src
docker build -t surfingpal-api .
docker run -p 8000:8000 surfingpal-api
```

3. **With docker-compose**:
```yaml
version: '3.8'
services:
  api:
    build: ./backend/www_forecast_api/src
    ports:
      - "8000:8000"
    environment:
      - CACHE_EXPIRE=3600
```

### Option 2: Cloud Platforms

#### Heroku

1. **Create Procfile**:
```
web: uvicorn main:app --host 0.0.0.0 --port $PORT
```

2. **Deploy**:
```bash
heroku create surfingpal-api
git push heroku main
```

#### AWS Lambda

1. **Install Mangum**:
```bash
pip install mangum
```

2. **Update main.py**:
```python
from mangum import Mangum

handler = Mangum(app)
```

3. **Deploy using Serverless Framework or AWS SAM**

#### Google Cloud Run

```bash
gcloud run deploy surfingpal-api --source ./backend/www_forecast_api/src
```

## Frontend Deployment

### Web App

1. **Build**:
```bash
cd frontend
flutter build web --release
```

2. **Deploy to**:
   - **Netlify**: Drag and drop `build/web` folder
   - **Vercel**: Connect GitHub repo, set build command: `flutter build web`
   - **Firebase Hosting**: `firebase deploy`
   - **GitHub Pages**: Push `build/web` to gh-pages branch

3. **Update API URL** in `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'https://your-api-domain.com';
```

### iOS App Store

1. **Configure**:
   - Update `ios/Runner.xcodeproj` bundle identifier
   - Set version in `pubspec.yaml`
   - Configure signing in Xcode

2. **Build**:
```bash
flutter build ios --release
```

3. **Archive in Xcode**:
   - Open `ios/Runner.xcworkspace`
   - Product → Archive
   - Distribute App → App Store Connect

### Android Play Store

1. **Generate signing key**:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. **Configure** `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-keystore>
```

3. **Update** `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

4. **Build**:
```bash
flutter build appbundle --release
```

5. **Upload** `build/app/outputs/bundle/release/app-release.aab` to Google Play Console

## Environment Configuration

### Backend

Create `.env` file:
```env
API_URL=https://marine-api.open-meteo.com/v1/marine
CACHE_EXPIRE=3600
CORS_ORIGINS=https://your-frontend-domain.com
```

### Frontend

Update `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'https://your-api-domain.com';
```

## Production Checklist

### Backend
- [ ] CORS configured for frontend domain
- [ ] Environment variables set
- [ ] Error handling and logging
- [ ] Rate limiting (if needed)
- [ ] HTTPS enabled
- [ ] Monitoring/health checks

### Frontend
- [ ] API URL updated
- [ ] App icons and splash screens
- [ ] Version numbers updated
- [ ] Privacy policy (if required)
- [ ] Terms of service (if required)
- [ ] Analytics configured (optional)

## Monitoring

### Backend
- Use FastAPI's built-in logging
- Add monitoring service (Sentry, DataDog, etc.)
- Set up health check endpoints

### Frontend
- Add crash reporting (Firebase Crashlytics, Sentry)
- Add analytics (Firebase Analytics, Mixpanel)

## Security

1. **API Security**:
   - Use HTTPS only
   - Implement rate limiting
   - Validate all inputs
   - Use environment variables for secrets

2. **App Security**:
   - Obfuscate code for release builds
   - Use secure storage for sensitive data
   - Implement certificate pinning (optional)

## Performance

1. **Backend**:
   - Use multiple workers: `--workers 4`
   - Enable caching
   - Optimize database queries (if added)

2. **Frontend**:
   - Minimize bundle size
   - Use code splitting
   - Optimize images
   - Enable compression
