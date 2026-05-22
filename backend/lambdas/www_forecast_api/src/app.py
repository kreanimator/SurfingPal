"""
Lambda handler for SurfingPal Forecast API
"""
import json
import time
import traceback
from typing import Dict, Any

from aws_xray_sdk.core import xray_recorder, patch_all

patch_all()
xray_recorder.configure(service='surfingpal-forecast-api', sampling=False)

from forecast_api import ForecastAPI, haversine_distance
from scoring import score_forecast

forecast_api = ForecastAPI()

CORS_HEADERS = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'content-type',
}


@xray_recorder.capture('lambda_handler')
def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    try:
        path = event.get('rawPath', '')
        method = event.get('requestContext', {}).get('http', {}).get('method', '')
        if path.startswith('/default'):
            path = path[8:]
        if not path:
            path = '/'

        if method == 'OPTIONS':
            return {'statusCode': 200, 'headers': CORS_HEADERS, 'body': ''}
        if path == '/' and method == 'GET':
            return _ok({'message': 'SurfingPal Forecast API', 'version': '1.0.0'})
        if path == '/health' and method == 'GET':
            return _ok({'status': 'healthy'})
        if path == '/api/forecast' and method == 'POST':
            return handle_forecast(event)

        return {'statusCode': 404, 'headers': CORS_HEADERS,
                'body': json.dumps({'error': 'Not found'})}
    except Exception as e:
        print(json.dumps({'level': 'error', 'error': str(e), 'trace': traceback.format_exc()}))
        return {'statusCode': 500, 'headers': CORS_HEADERS,
                'body': json.dumps({'error': 'Internal server error'})}


@xray_recorder.capture('handle_forecast')
def handle_forecast(event: Dict[str, Any]) -> Dict[str, Any]:
    t0 = time.time()
    log = {'route': 'POST /api/forecast'}

    try:
        body = event.get('body', '{}')
        if isinstance(body, str):
            body = json.loads(body)

        latitude = body.get('latitude')
        longitude = body.get('longitude')

        if latitude is None or longitude is None:
            log.update({'status': 400, 'reason': 'missing_coordinates', 'ms': _ms(t0)})
            print(json.dumps(log))
            return {'statusCode': 400, 'headers': CORS_HEADERS,
                    'body': json.dumps({
                        'error': 'Location is required. Please enable GPS or enter coordinates manually.',
                    })}

        log['coords'] = [round(latitude, 4), round(longitude, 4)]

        marine_forecast = forecast_api.get_forecast(latitude=latitude, longitude=longitude)
        marine_df = forecast_api.parse_api_response(marine_forecast)

        uv_ok = True
        try:
            weather_forecast = forecast_api.get_weather_forecast(latitude=latitude, longitude=longitude)
            weather_df = forecast_api.parse_weather_response(weather_forecast)
            marine_df = forecast_api.merge_weather_data(marine_df, weather_df)
        except Exception:
            uv_ok = False

        hourly = forecast_api.to_hourly_json(marine_df)
        scores = score_forecast(hourly, rules=forecast_api.CONDITION_RULESET)

        water_lat = marine_forecast.Latitude()
        water_lon = marine_forecast.Longitude()
        distance_km = round(haversine_distance(latitude, longitude, water_lat, water_lon), 1)

        payload = {
            "meta": {
                "source": "open-meteo marine weather api",
                "coordinates": {"latitude": water_lat, "longitude": water_lon,
                                "pretty": f'{water_lat}°N {water_lon}°E'},
                "requested_coordinates": {"latitude": latitude, "longitude": longitude},
                "distance_to_water_km": distance_km,
                "elevation_m_asl": marine_forecast.Elevation(),
                "utc_offset_seconds": marine_forecast.UtcOffsetSeconds(),
            },
            "scores": scores,
        }

        log.update({'status': 200, 'hours': len(hourly), 'distance_km': distance_km,
                     'uv': uv_ok, 'ms': _ms(t0)})
        print(json.dumps(log))
        return _ok(payload)

    except Exception as e:
        log.update({'status': 500, 'error': str(e), 'ms': _ms(t0)})
        print(json.dumps(log))
        return {'statusCode': 500, 'headers': CORS_HEADERS,
                'body': json.dumps({'error': f'Error fetching forecast: {str(e)}'})}


def _ok(body: dict) -> Dict[str, Any]:
    return {'statusCode': 200, 'headers': CORS_HEADERS, 'body': json.dumps(body)}


def _ms(t0: float) -> int:
    return int((time.time() - t0) * 1000)
