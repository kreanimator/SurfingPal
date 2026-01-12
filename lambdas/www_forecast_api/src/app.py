import json

import openmeteo_requests

import pandas as pd
import requests_cache
from openmeteo_sdk.WeatherApiResponse import WeatherApiResponse
from requests_cache import CachedSession
from retry_requests import retry



class ForecastAPI:
    app_config = {
        'api_url': 'https://marine-api.open-meteo.com/v1/marine',
        'test_geo': {
            'latitude': 32.3442996,
            'longitude': 34.8636596,
        },
        'params': 
            ['wave_height', 'wave_direction', 'wave_period', 'wind_wave_height',
             'wind_wave_direction', 'wind_wave_period', 'wind_wave_peak_period', 'swell_wave_direction',
             'swell_wave_height', 'swell_wave_period', 'swell_wave_peak_period', 'secondary_swell_wave_height', 
             'secondary_swell_wave_period', 'secondary_swell_wave_direction', 'sea_level_height_msl',
             'sea_surface_temperature', 'ocean_current_velocity', 'ocean_current_direction'],
    }



    def __init__(self):
        cache_session = requests_cache.CachedSession('.cache', expire_after=3600)
        retry_session = retry(cache_session, retries=3, backoff_factor=0.2)
        self.client = openmeteo_requests.Client(session=retry_session)

    def __call__(self, event: dict, *args, **kwargs):
        latitude = event.get('latitude',self.app_config["test_geo"]["latitude"])
        longitude = event.get('longitude',self.app_config["test_geo"]["longitude"])
        forecast = self.get_forecast(latitude=latitude, longitude=longitude)
        parsed_forecast = self.parse_api_response(forecast)
        payload = {
            'coordinates': f'{forecast.Latitude()}°N {forecast.Longitude()}°E',
            'elevation': f'{forecast.Elevation()}m asl',
            'timezone difference to GMT+0': f'{forecast.UtcOffsetSeconds()}s',
            'hourly_data': api.to_hourly_json(parsed_forecast)
        }
        response = json.dumps(payload, indent=2, ensure_ascii=False)
        print(response)
        return response

    def get_forecast(self, *, latitude: float, longitude: float) -> WeatherApiResponse:
        response = self.client.weather_api(
            self.app_config['api_url'],
            params={
                'latitude': latitude,
                'longitude': longitude,
                'hourly': self.app_config['params']
            }
            )
        return response[0]

    def parse_api_response(self, response: WeatherApiResponse) -> pd.DataFrame:
        hourly = response.Hourly()
        dates = pd.date_range(
            start=pd.to_datetime(hourly.Time(), unit='s', utc=True),
            end=pd.to_datetime(hourly.TimeEnd(), unit='s', utc=True),
            freq=pd.Timedelta(seconds=hourly.Interval()),
            inclusive='left'
        )
        data: dict[str, object] = {'date': dates}
        for i, name in enumerate(self.app_config['params']):
            data[name] = hourly.Variables(i).ValuesAsNumpy()

        return pd.DataFrame(data)

    @staticmethod
    def to_hourly_json(df: pd.DataFrame) -> list[dict]:
        out = df.copy()
        out["date"] = out["date"].dt.strftime("%Y-%m-%dT%H:%M:%SZ")
        return out.to_dict(orient="records")

if __name__ == "__main__":
    api = ForecastAPI()
    api({})