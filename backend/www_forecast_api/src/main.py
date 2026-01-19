from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional
import uvicorn

from forecast_api import ForecastAPI
from scoring import score_forecast

app = FastAPI(
    title="SurfingPal Forecast API",
    description="Marine weather forecast API for water sports",
    version="1.0.0"
)

# CORS middleware for Flutter web/mobile
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize the forecast API
forecast_api = ForecastAPI()


class ForecastRequest(BaseModel):
    latitude: Optional[float] = Field(
        None,
        description="Latitude coordinate (defaults to test location if not provided)",
        ge=-90,
        le=90
    )
    longitude: Optional[float] = Field(
        None,
        description="Longitude coordinate (defaults to test location if not provided)",
        ge=-180,
        le=180
    )


@app.get("/")
async def root():
    return {
        "message": "SurfingPal Forecast API",
        "version": "1.0.0",
        "endpoints": {
            "forecast": "/api/forecast",
            "health": "/health"
        }
    }


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.post("/api/forecast")
async def get_forecast(request: ForecastRequest):
    """
    Get marine weather forecast for water sports.
    
    Returns forecast data with scores for all enabled sports (surfing, SUP, windsurfing, kitesurfing, etc.)
    """
    try:
        # Use provided coordinates or defaults
        latitude = request.latitude if request.latitude is not None else forecast_api.app_config["test_geo"]["latitude"]
        longitude = request.longitude if request.longitude is not None else forecast_api.app_config["test_geo"]["longitude"]
        
        # Get marine forecast
        marine_forecast = forecast_api.get_forecast(latitude=latitude, longitude=longitude)
        marine_df = forecast_api.parse_api_response(marine_forecast)
        
        # Get weather forecast (UV index)
        try:
            weather_forecast = forecast_api.get_weather_forecast(latitude=latitude, longitude=longitude)
            weather_df = forecast_api.parse_weather_response(weather_forecast)
            # Merge UV index into marine data
            marine_df = forecast_api.merge_weather_data(marine_df, weather_df)
        except Exception as e:
            # If weather API fails, continue without UV index
            print(f"Warning: Could not fetch UV index: {e}")
        
        hourly = forecast_api.to_hourly_json(marine_df)
        scores = score_forecast(hourly, rules=forecast_api.CONDITION_RULESET)
        
        # Build response
        payload = {
            "meta": {
                "source": "open-meteo marine weather api",
                "coordinates": {
                    "latitude": marine_forecast.Latitude(),
                    "longitude": marine_forecast.Longitude(),
                    "pretty": f'{marine_forecast.Latitude()}°N {marine_forecast.Longitude()}°E',
                },
                "elevation_m_asl": marine_forecast.Elevation(),
                "utc_offset_seconds": marine_forecast.UtcOffsetSeconds(),
            },
            "scores": scores,
        }
        
        return payload
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching forecast: {str(e)}")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
