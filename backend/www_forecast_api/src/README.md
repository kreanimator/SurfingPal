# SurfingPal Backend API

FastAPI-based backend service for marine weather forecasts and water sports condition scoring.

## Features

- 🌊 Marine weather forecast integration (Open-Meteo API)
- 🏄‍♂️ Multi-sport condition scoring (Surfing, SUP, Windsurfing, Kitesurfing)
- ⚡ FastAPI with async support
- 🔒 CORS enabled for frontend integration
- 📊 Comprehensive scoring with safety limits
- 🎯 Context-aware recommendations

## Prerequisites

- **Python 3.10+**
- **pip** (Python package manager)

## Installation

1. **Navigate to the backend directory**:
   ```bash
   cd backend/www_forecast_api/src
   ```

2. **Create a virtual environment** (recommended):
   ```bash
   python3 -m venv venv
   
   # On Linux/Mac:
   source venv/bin/activate
   
   # On Windows:
   venv\Scripts\activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

## Running the Server

### Development Mode

```bash
python main.py
```

Or using uvicorn directly:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at:
- **API**: `http://localhost:8000`
- **Interactive Docs**: `http://localhost:8000/docs`
- **Alternative Docs**: `http://localhost:8000/redoc`

### Production Mode

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

## API Endpoints

### GET `/`
Health check and API information.

**Response:**
```json
{
  "message": "SurfingPal Forecast API",
  "version": "1.0.0",
  "endpoints": {
    "forecast": "/api/forecast",
    "health": "/health"
  }
}
```

### GET `/health`
Health check endpoint.

**Response:**
```json
{
  "status": "healthy"
}
```

### POST `/api/forecast`
Get marine weather forecast with sports condition scores.

**Request Body:**
```json
{
  "latitude": 32.3442996,  // Optional, defaults to test location
  "longitude": 34.8636596   // Optional, defaults to test location
}
```

**Response:**
```json
{
  "meta": {
    "source": "open-meteo marine weather api",
    "coordinates": {
      "latitude": 32.3442996,
      "longitude": 34.8636596,
      "pretty": "32.34°N 34.86°E"
    },
    "elevation_m_asl": 0.0,
    "utc_offset_seconds": 7200
  },
  "scores": [
    {
      "date": "2026-01-12T08:00:00Z",
      "sports": {
        "surfing": {
          "sport": "surfing",
          "date": "2026-01-12T08:00:00Z",
          "label": "great",
          "score": 0.85,
          "context": {
            "water_temp_c": 20.5,
            "wave_height_m": 1.2,
            "wave_period_s": 12.0,
            "current_kmh": 1.5
          },
          "flags": [],
          "reasons": ["Long-period swell", "Low chop"]
        },
        "sup": {
          "sport": "sup",
          "date": "2026-01-12T08:00:00Z",
          "label": "ok",
          "score": 0.65,
          "context": {
            "water_temp_c": 20.5,
            "wave_height_m": 0.4,
            "wind_wave_height_m": 0.2,
            "current_kmh": 1.5
          },
          "flags": [],
          "reasons": ["Calm surface"]
        }
      }
    }
  ]
}
```

## Supported Sports

1. **Surfing** - Traditional wave surfing
2. **SUP** - Stand-up paddleboarding (flatwater)
3. **SUP Surf** - SUP surfing
4. **Windsurfing** - Wind-powered surfing
5. **Kitesurfing** - Kite-powered surfing

Each sport has:
- **Label**: `great`, `ok`, `marginal`, or `bad`
- **Score**: 0.0 to 1.0 (higher is better)
- **Context**: Water temp, wave height, current, etc.
- **Flags**: Safety warnings if applicable
- **Reasons**: Human-readable explanations

## Configuration

### Default Location

The default test location is set in `app.py`:
```python
'test_geo': {
    'latitude': 32.3442996,
    'longitude': 34.8636596,
}
```

### CORS Settings

CORS is configured in `main.py`. For production, update `allow_origins`:

```python
allow_origins=["https://your-frontend-domain.com"]
```

### Cache Settings

Forecast data is cached for 1 hour (3600 seconds). Adjust in `app.py`:

```python
cache_session = requests_cache.CachedSession('.cache', expire_after=3600)
```

## Project Structure

```
backend/www_forecast_api/src/
├── main.py           # FastAPI application and endpoints
├── app.py            # ForecastAPI class and configuration
├── scoring.py        # Sports condition scoring logic
├── requirements.txt  # Python dependencies
└── README.md         # This file
```

## Development

### Running Tests

```bash
# Run the API and test with curl
curl -X POST "http://localhost:8000/api/forecast" \
     -H "Content-Type: application/json" \
     -d '{"latitude": 32.344, "longitude": 34.863}'
```

### Interactive API Documentation

FastAPI provides automatic interactive documentation:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

### Debugging

Enable debug mode:
```bash
uvicorn main:app --reload --log-level debug
```

## Deployment

### Docker (Recommended)

Create `Dockerfile`:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Build and run:
```bash
docker build -t surfingpal-api .
docker run -p 8000:8000 surfingpal-api
```

### Cloud Platforms

**Heroku:**
```bash
heroku create surfingpal-api
git push heroku main
```

**AWS Lambda:**
- Use Mangum adapter: `pip install mangum`
- Wrap app: `handler = Mangum(app)`

**Google Cloud Run:**
```bash
gcloud run deploy surfingpal-api --source .
```

## Environment Variables

For production, consider using environment variables:

```python
import os

API_URL = os.getenv('API_URL', 'https://marine-api.open-meteo.com/v1/marine')
CACHE_EXPIRE = int(os.getenv('CACHE_EXPIRE', '3600'))
```

## Performance

- Forecast data is cached for 1 hour
- API responses are typically < 500ms
- Supports concurrent requests via FastAPI async

## Troubleshooting

1. **Import errors**:
   - Ensure all dependencies are installed: `pip install -r requirements.txt`
   - Check Python version: `python --version` (should be 3.10+)

2. **Port already in use**:
   - Change port: `uvicorn main:app --port 8001`
   - Or kill process using port 8000

3. **API connection errors**:
   - Check internet connection
   - Verify Open-Meteo API is accessible
   - Check firewall settings

4. **CORS errors from frontend**:
   - Ensure CORS middleware is configured
   - Check `allow_origins` includes your frontend URL

## License

See main project LICENSE file.
