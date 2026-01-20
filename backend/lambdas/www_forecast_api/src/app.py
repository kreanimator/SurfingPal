"""
Lambda handler for SurfingPal Forecast API
Direct Lambda handler for API Gateway HTTP API events
"""
import json
import traceback
from typing import Dict, Any
from forecast_api import ForecastAPI
from scoring import score_forecast


# Initialize forecast API (reused across invocations)
forecast_api = ForecastAPI()


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for API Gateway HTTP API events
    
    Routes:
    - GET / -> API info
    - GET /health -> Health check
    - POST /api/forecast -> Get forecast
    """
    route_key = event.get('routeKey', '')
    http_method = event.get('requestContext', {}).get('http', {}).get('method', '')
    path = event.get('rawPath', '')
    
    # Handle CORS preflight
    if http_method == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Access-Control-Allow-Headers': 'content-type',
            },
            'body': ''
        }
    
    # Route handling
    if route_key == 'GET /' or path == '/':
        return handle_root()
    elif route_key == 'GET /health' or path == '/health':
        return handle_health()
    elif route_key == 'POST /api/forecast' or path == '/api/forecast':
        return handle_forecast(event)
    else:
        return {
            'statusCode': 404,
            'headers': get_cors_headers(),
            'body': json.dumps({'error': 'Not found'})
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


def handle_forecast(event: Dict[str, Any]) -> Dict[str, Any]:
    """Handle POST /api/forecast - Get forecast with sports scores"""
    try:
        # Parse request body
        body = event.get('body', '{}')
        if isinstance(body, str):
            body = json.loads(body)
        
        latitude = body.get('latitude')
        longitude = body.get('longitude')
        
        # Use provided coordinates or defaults
        if latitude is None:
            latitude = forecast_api.app_config["test_geo"]["latitude"]
        if longitude is None:
            longitude = forecast_api.app_config["test_geo"]["longitude"]
        
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
