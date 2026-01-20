import json
import os

import openmeteo_requests

import pandas as pd
import requests_cache
from openmeteo_sdk.WeatherApiResponse import WeatherApiResponse
from requests_cache import CachedSession
from retry_requests import retry
from scoring import score_forecast


class ForecastAPI:
    app_config = {
        'api_url': 'https://marine-api.open-meteo.com/v1/marine',
        'test_geo': {
            'latitude': 32.3442996,
            'longitude': 34.8636596,
        },
        'params': 
            ['wave_height', 'wave_direction', 'wave_period', 'wave_peak_period', 'wind_wave_height',
             'wind_wave_direction', 'wind_wave_period', 'wind_wave_peak_period', 'swell_wave_direction',
             'swell_wave_height', 'swell_wave_period', 'swell_wave_peak_period', 'secondary_swell_wave_height', 
             'secondary_swell_wave_period', 'secondary_swell_wave_direction', 'sea_level_height_msl',
             'sea_surface_temperature', 'ocean_current_velocity', 'ocean_current_direction'],
    }

    CONDITION_RULESET = {
        "meta": {
            "source": "open-meteo marine weather api",
            "notes": [
                "wave_direction is direction waves come FROM; ocean_current_direction is direction current flows TO.",
                "windsurf/kite scoring here uses wind_wave_* as a proxy; for real decisions add wind_speed_10m + wind_gusts_10m from Open-Meteo Weather API.",
            ],
        },

        # Common knobs you can reuse in your scorer
        "scoring": {
            "output": {
                "label_thresholds": {
                    "great": 0.75,
                    "ok": 0.55,
                    "marginal": 0.40,
                    "bad": 0.00,
                }
            },
            "penalties": {
                # If currents are strong, many sports become less safe/less fun
                "current_velocity_kmh": {
                    "warn_from": 3.0,  # start penalizing
                    "hard_from": 6.0,  # heavy penalty
                },
                # sea_level_height_msl is tides-ish; without local bathymetry it’s not very actionable,
                # but you may still use it to show "tide rising/falling" rather than scoring.
            },
        },

        "sports": {
            # 1) Surfing (shortboard / general)
            "surfing": {
                "enabled": True,
                "inputs": [
                    "wave_height", "wave_period", "wave_peak_period",
                    "wind_wave_height", "wind_wave_period",
                    "swell_wave_height", "swell_wave_period",
                    "ocean_current_velocity",
                    "sea_surface_temperature",
                ],
                "hard_limits": {
                    "current_velocity_kmh": {"bad_from": 8.0},  # very strong current
                },
                "thresholds": {
                    # "fun zone"
                    "wave_height_m": {"min": 0.6, "ideal": (0.9, 2.0), "max": 3.0},
                    "wave_period_s": {"min": 7.0, "ideal": (9.0, 14.0), "max": 18.0},
                    # cleaner surf tends to be swell-dominant, not wind-chop dominant
                    "wind_wave_height_m": {"ideal_max": 0.5, "bad_from": 0.9},
                    "wind_wave_period_s": {"bad_max": 4.0},  # short-period chop
                    "swell_share": {
                        # swell_share = swell_wave_height / max(wave_height, eps)
                        "good_from": 0.6,
                        "great_from": 0.75,
                    },
                    "current_velocity_kmh": {"warn_from": 3.0, "bad_from": 6.0},
                    "water_temp_c": {"nice_from": 18.0},  # UX-only "comfort"
                },
                "weights": {
                    "wave_height": 0.30,
                    "wave_period": 0.25,
                    "cleanliness": 0.25,  # from wind_wave_* + swell_share
                    "current": 0.20,
                },
                "context_fields": [
                    "sea_surface_temperature",
                    "wave_height",
                    "wave_period",
                    "ocean_current_velocity",
                    "uv_index",
                ],
                "ux": {
                    "chips": [
                        {"label": "Wave", "fields": ["wave_height", "wave_period", "wave_direction"]},
                        {"label": "Swell",
                         "fields": ["swell_wave_height", "swell_wave_period", "swell_wave_direction"]},
                        {"label": "Chop", "fields": ["wind_wave_height", "wind_wave_period", "wind_wave_direction"]},
                        {"label": "Current", "fields": ["ocean_current_velocity", "ocean_current_direction"]},
                        {"label": "Water", "fields": ["sea_surface_temperature"]},
                    ]
                },
            },

            # 2) SUP (flatwater / cruising)
            "sup": {
                "enabled": True,
                "inputs": [
                    "wave_height", "wind_wave_height", "wind_wave_period",
                    "ocean_current_velocity",
                    "sea_surface_temperature",
                ],
                "hard_limits": {
                    "wave_height_m": {"bad_from": 0.8},  # above this, not safe for SUP
                    "wind_wave_height_m": {"bad_from": 0.45},  # too choppy
                    "current_velocity_kmh": {"bad_from": 5.0},  # too strong current
                },
                "thresholds": {
                    # SUP flatwater likes low waves/chop
                    "wave_height_m": {"great_max": 0.3, "ok_max": 0.5},
                    "wind_wave_height_m": {"great_max": 0.15, "ok_max": 0.25},
                    "wind_wave_period_s": {"bad_max": 3.5},
                    "current_velocity_kmh": {"warn_from": 2.5, "bad_from": 5.0},
                    "water_temp_c": {"nice_from": 18.0},
                },
                "weights": {
                    "calmness": 0.80,  # wave_height + wind_wave_*
                    "current": 0.20,
                },
                "context_fields": [
                    "sea_surface_temperature",
                    "wave_height",
                    "wind_wave_height",
                    "ocean_current_velocity",
                    "uv_index",
                ],
                "ux": {
                    "primary_message": "Calmer is better for SUP. Small chop quickly becomes tiring.",
                },
            },

            # 3) SUP Surf (optional extra mode; still "SUP", but wave-focused)
            "sup_surf": {
                "enabled": True,
                "inputs": [
                    "wave_height", "wave_period",
                    "wind_wave_height", "wind_wave_period",
                    "ocean_current_velocity",
                ],
                "hard_limits": {
                    "wave_height_m": {"bad_from": 2.8},  # too big for SUP surf
                    "wind_wave_height_m": {"bad_from": 1.2},  # too choppy
                    "current_velocity_kmh": {"bad_from": 6.0},
                },
                "thresholds": {
                    "wave_height_m": {"min": 0.4, "ideal": (0.6, 1.5), "max": 2.5},
                    "wave_period_s": {"min": 7.0, "ideal": (8.5, 13.0), "max": 18.0},
                    "wind_wave_height_m": {"ideal_max": 0.6, "bad_from": 1.0},
                    "wind_wave_period_s": {"bad_max": 4.0},
                    "current_velocity_kmh": {"warn_from": 3.0, "bad_from": 6.0},
                },
                "weights": {
                    "wave": 0.55,
                    "cleanliness": 0.30,
                    "current": 0.15,
                },
                "context_fields": [
                    "wave_height",
                    "wave_period",
                    "wind_wave_height",
                    "ocean_current_velocity",
                    "uv_index",
                ],
            },

            # 4) Windsurfing (wave/water-state proxy — add real wind later)
            "windsurfing": {
                "enabled": True,
                "inputs": [
                    "wind_wave_height", "wind_wave_period",
                    "wave_height", "wave_period",
                    "ocean_current_velocity",
                ],
                "hard_limits": {
                    "wave_height_m": {"bad_from": 4.5},  # too dangerous
                    "current_velocity_kmh": {"bad_from": 7.0},
                },
                "thresholds": {
                    # Using wind_wave_height as "there is wind energy on the surface"
                    "wind_wave_height_m": {"min": 0.25, "ideal": (0.4, 1.2), "max": 2.0},
                    # Too short => messy slop; too big => advanced conditions
                    "wind_wave_period_s": {"min": 2.0, "ideal": (2.5, 5.0), "max": 7.0},

                    # Optional: wave sailing vs freeride.
                    "wave_height_m": {"ok_max": 2.5, "bad_from": 4.0},
                    "wave_period_s": {"ok_range": (6.0, 14.0)},
                    "current_velocity_kmh": {"warn_from": 3.0, "bad_from": 6.0},
                },
                "weights": {
                    "wind_proxy": 0.55,
                    "sea_state": 0.25,
                    "current": 0.20,
                },
                "context_fields": [
                    "wave_height",
                    "wave_period",
                    "wind_wave_height",
                    "ocean_current_velocity",
                    "uv_index",
                ],
                "ux": {
                    "primary_message": "This uses wind-waves as a wind proxy. Add wind_speed_10m for reliable windsurf calls.",
                },
            },

            # 5) Kitesurfing (wave/water-state proxy — add real wind later)
            "kitesurfing": {
                "enabled": True,
                "inputs": [
                    "wind_wave_height", "wind_wave_period",
                    "wave_height",
                    "ocean_current_velocity",
                ],
                "hard_limits": {
                    "wave_height_m": {"bad_from": 4.0},  # too dangerous
                    "current_velocity_kmh": {"bad_from": 7.0},
                },
                "thresholds": {
                    # Many kite sessions happen in choppy but manageable sea states
                    "wind_wave_height_m": {"min": 0.2, "ideal": (0.3, 0.9), "max": 1.6},
                    "wind_wave_period_s": {"min": 1.8, "ideal": (2.2, 4.5), "max": 6.5},
                    "wave_height_m": {"ok_max": 2.0, "bad_from": 3.5},
                    "current_velocity_kmh": {"warn_from": 3.0, "bad_from": 6.0},
                },
                "weights": {
                    "wind_proxy": 0.60,
                    "sea_state": 0.20,
                    "current": 0.20,
                },
                "context_fields": [
                    "wave_height",
                    "wind_wave_height",
                    "ocean_current_velocity",
                    "uv_index",
                ],
                "ux": {
                    "primary_message": "Proxy-based. For kite, wind strength & gusts matter most — combine with Weather API wind.",
                },
            },
        },
    }

    def __init__(self):
        # Use /tmp for Lambda (ephemeral storage) or .cache for local development
        cache_dir = '/tmp' if os.environ.get('AWS_LAMBDA_FUNCTION_NAME') else '.cache'
        cache_session = requests_cache.CachedSession(
            os.path.join(cache_dir, 'forecast_cache'),
            expire_after=3600
        )
        retry_session = retry(cache_session, retries=3, backoff_factor=0.2)
        self.client = openmeteo_requests.Client(session=retry_session)

    def __call__(self, event: dict, *args, **kwargs):
        latitude = event.get('latitude',self.app_config["test_geo"]["latitude"])
        longitude = event.get('longitude',self.app_config["test_geo"]["longitude"])
        
        # Get marine forecast
        marine_forecast = self.get_forecast(latitude=latitude, longitude=longitude)
        df = self.parse_api_response(marine_forecast)
        
        # Get weather forecast (UV index)
        try:
            weather_forecast = self.get_weather_forecast(latitude=latitude, longitude=longitude)
            weather_df = self.parse_weather_response(weather_forecast)
            # Merge UV index into marine data
            df = self.merge_weather_data(df, weather_df)
        except Exception as e:
            # If weather API fails, continue without UV index
            print(f"Warning: Could not fetch UV index: {e}")
        
        hourly = self.to_hourly_json(df)
        scores = score_forecast(hourly, rules=self.CONDITION_RULESET)
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
            # "hourly": hourly,  # raw hourly (charts/debug)
            "scores": scores,  # UX-ready scoring output
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
    
    def get_weather_forecast(self, *, latitude: float, longitude: float) -> WeatherApiResponse:
        """Fetch UV index and other weather data from Open-Meteo Weather API"""
        weather_api_url = 'https://api.open-meteo.com/v1/forecast'
        response = self.client.weather_api(
            weather_api_url,
            params={
                'latitude': latitude,
                'longitude': longitude,
                'hourly': ['uv_index']  # UV index for tips
            }
        )
        return response[0]
    
    def parse_weather_response(self, response: WeatherApiResponse) -> pd.DataFrame:
        """Parse weather API response to extract UV index"""
        hourly = response.Hourly()
        dates = pd.date_range(
            start=pd.to_datetime(hourly.Time(), unit='s', utc=True),
            end=pd.to_datetime(hourly.TimeEnd(), unit='s', utc=True),
            freq=pd.Timedelta(seconds=hourly.Interval()),
            inclusive='left'
        )
        data: dict[str, object] = {'date': dates}
        
        # Extract UV index - since we only request uv_index, it's at index 0
        if hourly.VariablesLength() > 0:
            data['uv_index'] = hourly.Variables(0).ValuesAsNumpy()
        
        return pd.DataFrame(data)

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
    
    def merge_weather_data(self, marine_df: pd.DataFrame, weather_df: pd.DataFrame) -> pd.DataFrame:
        """Merge UV index from weather API into marine forecast DataFrame"""
        # Merge on date - only merge uv_index column
        uv_cols = ['date']
        if 'uv_index' in weather_df.columns:
            uv_cols.append('uv_index')
        
        merged = marine_df.merge(
            weather_df[uv_cols],
            on='date',
            how='left'
        )
        
        return merged

if __name__ == "__main__":
    api = ForecastAPI()
    api({})