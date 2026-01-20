"""
Lambda handler for SurfingPal Forecast API
Direct Lambda handler for API Gateway HTTP API events
"""
import json
import os
import traceback
from typing import Dict, Any

# X-Ray SDK setup
from aws_xray_sdk.core import xray_recorder, patch_all

# Patch all libraries for X-Ray tracing (patches boto3, requests, etc.)
patch_all()

# Configure X-Ray for Lambda (Lambda runtime handles context automatically)
xray_recorder.configure(
    service='surfingpal-forecast-api',
    sampling=False  # Lambda handles sampling automatically
)

from forecast_api import ForecastAPI
from scoring import score_forecast


# Initialize forecast API (reused across invocations)
forecast_api = ForecastAPI()


@xray_recorder.capture('lambda_handler')
def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for API Gateway HTTP API events
    Direct integration - routes are handled by API Gateway
    """
    try:
        # Extract path and method (strip stage prefix if present)
        path = event.get('rawPath', '')
        http_method = event.get('requestContext', {}).get('http', {}).get('method', '')
        
        # Remove stage prefix (/default) if present
        if path.startswith('/default'):
            path = path[8:]  # Remove '/default'
        if not path:
            path = '/'
        
        print(f"Request: {http_method} {path}")
        
        # Handle CORS preflight requests
        if http_method == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': get_cors_headers(),
                'body': ''
            }
        
        # Route handling
        if path == '/' and http_method == 'GET':
            return handle_root()
        elif path == '/health' and http_method == 'GET':
            return handle_health()
        elif path == '/api/forecast' and http_method == 'POST':
            return handle_forecast(event)
        else:
            print(f"Route not found: {http_method} {path}")
            return {
                'statusCode': 404,
                'headers': get_cors_headers(),
                'body': json.dumps({'error': 'Not found'})
            }
    except Exception as e:
        print(f"Unhandled exception in lambda_handler: {str(e)}")
        traceback.print_exc()
        return {
            'statusCode': 500,
            'headers': get_cors_headers(),
            'body': json.dumps({'error': f'Internal server error: {str(e)}'})
        }


def handle_root() -> Dict[str, Any]:
    """Handle GET / - API information"""
    return {
        'statusCode': 200,
        'headers': get_cors_headers(),
        'body': json.dumps({
            'message': 'SurfingPal Forecast API',
            'version': '1.0.0',
            'endpoints': {
                'forecast': '/api/forecast',
                'health': '/health'
            }
        })
    }


def handle_health() -> Dict[str, Any]:
    """Handle GET /health - Health check"""
    return {
        'statusCode': 200,
        'headers': get_cors_headers(),
        'body': json.dumps({'status': 'healthy'})
    }


@xray_recorder.capture('handle_forecast')
def handle_forecast(event: Dict[str, Any]) -> Dict[str, Any]:
    """Handle POST /api/forecast - Get forecast with sports scores"""
    try:
        print("Starting forecast request processing")
        
        # Parse request body
        body = event.get('body', '{}')
        print(f"Request body: {body}")
        if isinstance(body, str):
            body = json.loads(body)
        
        latitude = body.get('latitude')
        longitude = body.get('longitude')
        
        # Use provided coordinates or defaults
        if latitude is None:
            latitude = forecast_api.app_config["test_geo"]["latitude"]
        if longitude is None:
            longitude = forecast_api.app_config["test_geo"]["longitude"]
        
        print(f"Using coordinates: lat={latitude}, lon={longitude}")
        
        # Get marine forecast
        print("Fetching marine forecast...")
        marine_forecast = forecast_api.get_forecast(latitude=latitude, longitude=longitude)
        print("Parsing marine forecast response...")
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
        
        print("Converting to hourly JSON...")
        hourly = forecast_api.to_hourly_json(marine_df)
        print(f"Scoring forecast for {len(hourly)} hours...")
        scores = score_forecast(hourly, rules=forecast_api.CONDITION_RULESET)
        print("Forecast processing complete")
        
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
        
        return {
            'statusCode': 200,
            'headers': get_cors_headers(),
            'body': json.dumps(payload)
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        traceback.print_exc()
        return {
            'statusCode': 500,
            'headers': get_cors_headers(),
            'body': json.dumps({'error': f'Error fetching forecast: {str(e)}'})
        }


def get_cors_headers() -> Dict[str, str]:
    """Get CORS headers"""
    return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'content-type',
    }
