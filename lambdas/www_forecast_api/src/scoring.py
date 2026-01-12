
import math
from typing import Any, Iterable


def _clamp01(x: float) -> float:
    return 0.0 if x <= 0 else 1.0 if x >= 1 else x


def _safe_float(x: Any) -> float | None:
    try:
        if x is None:
            return None
        v = float(x)
        if math.isnan(v) or math.isinf(v):
            return None
        return v
    except Exception:
        return None


def _kmh_from_ms(v_ms: float | None) -> float | None:
    if v_ms is None:
        return None
    return v_ms * 3.6


def _score_range(
    v: float | None,
    *,
    min_v: float | None = None,
    ideal: tuple[float, float] | None = None,
    max_v: float | None = None,
    great_max: float | None = None,
    ok_max: float | None = None,
    ideal_max: float | None = None,
    bad_from: float | None = None,
    bad_max: float | None = None,
) -> float | None:
    """
    Generic scorer for a single variable.
    Returns 0..1 (higher is better) or None if can't score.
    Supports:
      - min/ideal/max “mountain” shape (best in ideal range)
      - great_max/ok_max/bad_from “smaller is better”
      - ideal_max/bad_from “smaller is better” simplified
      - bad_max “must be <= bad_max”
    """
    if v is None:
        return None

    # Hard reject-style
    if bad_from is not None and v >= bad_from:
        return 0.0
    if bad_max is not None and v > bad_max:
        return 0.0
    if min_v is not None and v < min_v:
        # linear ramp from min_v*0.7..min_v is too arbitrary, so simple:
        return _clamp01(v / min_v)

    # Smaller-is-better profiles
    if great_max is not None and ok_max is not None:
        if v <= great_max:
            return 1.0
        if v <= ok_max:
            # 1 -> 0.6
            return 1.0 - 0.4 * ((v - great_max) / max(ok_max - great_max, 1e-9))
        # beyond ok_max: decay to 0 at bad_from if defined, else at 2*ok_max
        end = bad_from if bad_from is not None else (2.0 * ok_max)
        return _clamp01(0.6 * (1.0 - ((v - ok_max) / max(end - ok_max, 1e-9))))

    if ideal_max is not None:
        if v <= ideal_max:
            return 1.0
        end = bad_from if bad_from is not None else (2.0 * ideal_max)
        return _clamp01(1.0 - ((v - ideal_max) / max(end - ideal_max, 1e-9)))

    # Mountain shape
    if ideal and max_v is not None:
        lo, hi = ideal
        if v <= lo:
            # ramp from min_v -> lo
            left = min_v if min_v is not None else lo * 0.5
            return _clamp01((v - left) / max(lo - left, 1e-9))
        if v <= hi:
            return 1.0
        # decay hi -> max_v
        return _clamp01(1.0 - ((v - hi) / max(max_v - hi, 1e-9)))

    # If only min/max provided
    if max_v is not None:
        return _clamp01(1.0 - (max(0.0, v - max_v) / max(max_v, 1e-9)))

    return None


def _label_from_score(score: float, thresholds: dict[str, float]) -> str:
    # thresholds like {"great":0.75,"ok":0.55,"marginal":0.4,"bad":0.0}
    for label, t in sorted(thresholds.items(), key=lambda kv: kv[1], reverse=True):
        if score >= t:
            return label
    return "bad"


def _pick_reasons(sport: str, metrics: dict[str, float | None], subscores: dict[str, float]) -> list[str]:
    reasons: list[str] = []

    # Generic “nice” reasons for any sport
    wh = metrics.get("wave_height")
    wp = metrics.get("wave_period")
    wwh = metrics.get("wind_wave_height")
    curr = metrics.get("ocean_current_velocity_kmh")

    if sport in {"surfing", "sup_surf"}:
        if wp is not None and wp >= 10:
            reasons.append("Long-period swell")
        if wwh is not None and wwh <= 0.5:
            reasons.append("Low chop")
        if curr is not None and curr <= 3.0:
            reasons.append("Mild current")

    if sport == "sup":
        if wh is not None and wh <= 0.5:
            reasons.append("Calm surface")
        if curr is not None and curr <= 2.5:
            reasons.append("Easy current")

    if sport in {"windsurfing", "kitesurfing"}:
        if wwh is not None and wwh >= 0.35:
            reasons.append("Wind-sea present (proxy)")
        if curr is not None and curr <= 3.0:
            reasons.append("Mild current")

    # Keep it short
    return reasons[:3]


def score_hour_for_sport(
    hour: dict[str, Any],
    *,
    sport_key: str,
    rules: dict[str, Any],
) -> dict[str, Any]:
    """
    hour: one element from to_hourly_json() list (keys like wave_height, wave_period, ...)
    rules: WATER_SPORT_RULES dict
    """
    sport = rules["sports"][sport_key]
    thresholds = rules["scoring"]["output"]["label_thresholds"]

    # normalize metrics (also derive current km/h)
    metrics: dict[str, float | None] = {}
    for k, v in hour.items():
        if k == "date":
            continue
        metrics[k] = _safe_float(v)

    metrics["ocean_current_velocity_kmh"] = _kmh_from_ms(metrics.get("ocean_current_velocity"))

    # helper for swell share
    wave_h = metrics.get("wave_height")
    swell_h = metrics.get("swell_wave_height")
    swell_share = None
    if wave_h is not None and wave_h > 0 and swell_h is not None:
        swell_share = swell_h / max(wave_h, 1e-6)
    metrics["swell_share"] = swell_share

    subscores: dict[str, float] = {}

    # Surf “wave” block
    th = sport.get("thresholds", {})

    # Wave height
    if "wave_height_m" in th:
        subs = _score_range(
            metrics.get("wave_height"),
            min_v=th["wave_height_m"].get("min"),
            ideal=th["wave_height_m"].get("ideal"),
            max_v=th["wave_height_m"].get("max"),
            great_max=th["wave_height_m"].get("great_max"),
            ok_max=th["wave_height_m"].get("ok_max"),
            bad_from=th["wave_height_m"].get("bad_from"),
        )
        if subs is not None:
            subscores["wave_height"] = subs

    # Wave period
    if "wave_period_s" in th:
        subs = _score_range(
            metrics.get("wave_period"),
            min_v=th["wave_period_s"].get("min"),
            ideal=th["wave_period_s"].get("ideal"),
            max_v=th["wave_period_s"].get("max"),
        )
        if subs is not None:
            subscores["wave_period"] = subs

    # Chop / wind-wave
    chop_parts: list[float] = []
    if "wind_wave_height_m" in th:
        subs = _score_range(
            metrics.get("wind_wave_height"),
            ideal_max=th["wind_wave_height_m"].get("ideal_max"),
            great_max=th["wind_wave_height_m"].get("great_max"),
            ok_max=th["wind_wave_height_m"].get("ok_max"),
            bad_from=th["wind_wave_height_m"].get("bad_from"),
        )
        if subs is not None:
            chop_parts.append(subs)
    if "wind_wave_period_s" in th:
        subs = _score_range(
            metrics.get("wind_wave_period"),
            bad_max=th["wind_wave_period_s"].get("bad_max"),
            min_v=th["wind_wave_period_s"].get("min"),
            ideal=th["wind_wave_period_s"].get("ideal"),
            max_v=th["wind_wave_period_s"].get("max"),
        )
        if subs is not None:
            chop_parts.append(subs)

    # Swell share for surf
    if "swell_share" in th:
        ss = metrics.get("swell_share")
        if ss is not None:
            good_from = th["swell_share"].get("good_from", 0.6)
            great_from = th["swell_share"].get("great_from", 0.75)
            if ss >= great_from:
                chop_parts.append(1.0)
            elif ss >= good_from:
                # 0.7..1.0
                chop_parts.append(0.7 + 0.3 * ((ss - good_from) / max(great_from - good_from, 1e-9)))
            else:
                chop_parts.append(_clamp01(ss / max(good_from, 1e-9)))

    if chop_parts:
        subscores["cleanliness"] = sum(chop_parts) / len(chop_parts)

    # Calmness for SUP
    if sport_key == "sup":
        calm_parts: list[float] = []
        if "wave_height_m" in th:
            subs = _score_range(
                metrics.get("wave_height"),
                great_max=th["wave_height_m"].get("great_max"),
                ok_max=th["wave_height_m"].get("ok_max"),
                bad_from=th["wave_height_m"].get("bad_from"),
            )
            if subs is not None:
                calm_parts.append(subs)
        if "wind_wave_height_m" in th:
            subs = _score_range(
                metrics.get("wind_wave_height"),
                great_max=th["wind_wave_height_m"].get("great_max"),
                ok_max=th["wind_wave_height_m"].get("ok_max"),
                bad_from=th["wind_wave_height_m"].get("bad_from"),
            )
            if subs is not None:
                calm_parts.append(subs)
        if "wind_wave_period_s" in th:
            subs = _score_range(
                metrics.get("wind_wave_period"),
                bad_max=th["wind_wave_period_s"].get("bad_max"),
            )
            if subs is not None:
                calm_parts.append(subs)
        if calm_parts:
            subscores["calmness"] = sum(calm_parts) / len(calm_parts)

    # Wind proxy for windsurf/kite
    if sport_key in {"windsurfing", "kitesurfing"}:
        proxy_parts: list[float] = []
        if "wind_wave_height_m" in th:
            subs = _score_range(
                metrics.get("wind_wave_height"),
                min_v=th["wind_wave_height_m"].get("min"),
                ideal=th["wind_wave_height_m"].get("ideal"),
                max_v=th["wind_wave_height_m"].get("max"),
            )
            if subs is not None:
                proxy_parts.append(subs)
        if "wind_wave_period_s" in th:
            subs = _score_range(
                metrics.get("wind_wave_period"),
                min_v=th["wind_wave_period_s"].get("min"),
                ideal=th["wind_wave_period_s"].get("ideal"),
                max_v=th["wind_wave_period_s"].get("max"),
            )
            if subs is not None:
                proxy_parts.append(subs)
        if proxy_parts:
            subscores["wind_proxy"] = sum(proxy_parts) / len(proxy_parts)

        # sea_state: prefer not-too-crazy overall wave height
        if "wave_height_m" in th:
            subs = _score_range(
                metrics.get("wave_height"),
                great_max=None,
                ok_max=th["wave_height_m"].get("ok_max"),
                bad_from=th["wave_height_m"].get("bad_from"),
            )
            if subs is not None:
                subscores["sea_state"] = subs

    # Current (universal)
    curr_th = th.get("current_velocity_kmh")
    if curr_th:
        cv = metrics.get("ocean_current_velocity_kmh")
        if cv is not None:
            warn_from = curr_th.get("warn_from", 3.0)
            bad_from = curr_th.get("bad_from", 6.0)
            if cv <= warn_from:
                subscores["current"] = 1.0
            elif cv >= bad_from:
                subscores["current"] = 0.0
            else:
                subscores["current"] = _clamp01(1.0 - ((cv - warn_from) / max(bad_from - warn_from, 1e-9)))

    # Water temp (comfort; optional)
    if "water_temp_c" in th:
        wt = metrics.get("sea_surface_temperature")
        nice_from = th["water_temp_c"].get("nice_from", 18.0)
        if wt is not None:
            subscores["water_temp"] = _clamp01(wt / nice_from) if wt < nice_from else 1.0

    # Weighted aggregation (only for keys present)
    weights = sport.get("weights", {})
    num = 0.0
    den = 0.0
    for k, w in weights.items():
        if k in subscores:
            num += subscores[k] * float(w)
            den += float(w)
    score = (num / den) if den > 0 else 0.0

    # global penalty for hard currents (optional)
    penalty_cfg = rules["scoring"].get("penalties", {}).get("current_velocity_kmh", {})
    cv = metrics.get("ocean_current_velocity_kmh")
    if cv is not None and penalty_cfg:
        warn = penalty_cfg.get("warn_from", 3.0)
        hard = penalty_cfg.get("hard_from", 6.0)
        if cv >= hard:
            score *= 0.6
        elif cv >= warn:
            # mild penalty up to 15%
            score *= (1.0 - 0.15 * ((cv - warn) / max(hard - warn, 1e-9)))

    score = _clamp01(score)
    label = _label_from_score(score, thresholds)

    return {
        "sport": sport_key,
        "score": round(score, 3),
        "label": label,
        "reasons": _pick_reasons(sport_key, metrics, subscores),
        "subscores": {k: round(v, 3) for k, v in subscores.items()},
    }


def score_forecast(
    hourly_records: list[dict[str, Any]],
    *,
    rules: dict[str, Any],
    sports: Iterable[str] | None = None,
) -> list[dict[str, Any]]:
    sports_list = list(sports) if sports is not None else [
        k for k, v in rules["sports"].items() if v.get("enabled", True)
    ]

    out: list[dict[str, Any]] = []
    for hour in hourly_records:
        row = {
            "date": hour.get("date"),
            "sports": {s: score_hour_for_sport(hour, sport_key=s, rules=rules) for s in sports_list},
        }
        out.append(row)
    return out
