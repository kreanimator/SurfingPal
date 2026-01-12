import json

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
                "thresholds": {
                    # “fun zone”
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
                    "water_temp_c": {"nice_from": 18.0},  # UX-only “comfort”
                },
                "weights": {
                    "wave_height": 0.30,
                    "wave_period": 0.25,
                    "cleanliness": 0.25,  # from wind_wave_* + swell_share
                    "current": 0.10,
                    "water_temp": 0.10,
                },
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
                "thresholds": {
                    # SUP flatwater likes low waves/chop
                    "wave_height_m": {"great_max": 0.4, "ok_max": 0.7, "bad_from": 1.0},
                    "wind_wave_height_m": {"great_max": 0.2, "ok_max": 0.35, "bad_from": 0.6},
                    "wind_wave_period_s": {"bad_max": 3.5},
                    "current_velocity_kmh": {"warn_from": 2.5, "bad_from": 5.0},
                    "water_temp_c": {"nice_from": 18.0},
                },
                "weights": {
                    "calmness": 0.60,  # wave_height + wind_wave_*
                    "current": 0.25,
                    "water_temp": 0.15,
                },
                "ux": {
                    "primary_message": "Calmer is better for SUP. Small chop quickly becomes tiring.",
                },
            },

            # 3) SUP Surf (optional extra mode; still “SUP”, but wave-focused)
            "sup_surf": {
                "enabled": True,
                "inputs": [
                    "wave_height", "wave_period",
                    "wind_wave_height", "wind_wave_period",
                    "ocean_current_velocity",
                ],
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
            },

            # 4) Windsurfing (wave/water-state proxy — add real wind later)
            "windsurfing": {
                "enabled": True,
                "inputs": [
                    "wind_wave_height", "wind_wave_period",
                    "wave_height", "wave_period",
                    "ocean_current_velocity",
                ],
                "thresholds": {
                    # Using wind_wave_height as “there is wind energy on the surface”
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
                "ux": {
                    "primary_message": "Proxy-based. For kite, wind strength & gusts matter most — combine with Weather API wind.",
                },
            },
        },
    }

    def __init__(self):
        cache_session = requests_cache.CachedSession('.cache', expire_after=3600)
        retry_session = retry(cache_session, retries=3, backoff_factor=0.2)
        self.client = openmeteo_requests.Client(session=retry_session)

    def __call__(self, event: dict, *args, **kwargs):
        latitude = event.get('latitude',self.app_config["test_geo"]["latitude"])
        longitude = event.get('longitude',self.app_config["test_geo"]["longitude"])
        forecast = self.get_forecast(latitude=latitude, longitude=longitude)
        df = self.parse_api_response(forecast)
        hourly = self.to_hourly_json(df)
        scores = score_forecast(hourly, rules=self.CONDITION_RULESET)
        payload = {
            "meta": {
                "source": "open-meteo marine weather api",
                "coordinates": {
                    "latitude": forecast.Latitude(),
                    "longitude": forecast.Longitude(),
                    "pretty": f'{forecast.Latitude()}°N {forecast.Longitude()}°E',
                },
                "elevation_m_asl": forecast.Elevation(),
                "utc_offset_seconds": forecast.UtcOffsetSeconds(),
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