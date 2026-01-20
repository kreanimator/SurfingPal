
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


def _check_hard_limits(
    metrics: dict[str, float | None],
    hard_limits: dict[str, dict[str, float]],
    sport_key: str,
) -> tuple[list[str], list[str]]:
    """
    Check hard limits and return flags and reasons for violations.
    Returns: (flags, reasons)
    """
    flags: list[str] = []
    reasons: list[str] = []

    for limit_key, limit_cfg in hard_limits.items():
        # Map limit keys to metric keys
        metric_key_map = {
            "wave_height_m": "wave_height",
            "wind_wave_height_m": "wind_wave_height",
            "current_velocity_kmh": "ocean_current_velocity_kmh",
        }
        metric_key = metric_key_map.get(limit_key, limit_key.replace("_m", "").replace("_kmh", "_kmh"))
        
        value = metrics.get(metric_key)
        if value is None:
            continue

        bad_from = limit_cfg.get("bad_from")
        if bad_from is not None and value >= bad_from:
            # Generate flag name with sport context
            if "wave_height" in limit_key and sport_key == "sup":
                flags.append("too_wavy_for_sup")
                reasons.append(f"Wave height {value:.2f}m is above SUP safety limit {bad_from:.2f}m")
            elif "wave_height" in limit_key:
                flags.append("too_wavy")
                reasons.append(f"Wave height {value:.2f}m exceeds safety limit {bad_from:.2f}m")
            elif "wind_wave_height" in limit_key:
                flags.append("too_choppy")
                reasons.append(f"Wind wave height {value:.2f}m exceeds limit {bad_from:.2f}m")
            elif "current" in limit_key:
                flags.append("current_too_strong")
                reasons.append(f"Current {value:.2f} km/h exceeds safety limit {bad_from:.2f} km/h")

    return flags, reasons


def _pick_reasons(
    sport: str,
    metrics: dict[str, float | None],
    subscores: dict[str, float],
    flags: list[str],
) -> list[str]:
    """
    Generate positive reasons when conditions are good.
    Negative reasons (from hard limits) are handled separately.
    """
    reasons: list[str] = []

    # If we have hard limit violations, those are already in flags/reasons
    if flags:
        return reasons  # Don't add positive reasons if unsafe

    # Generic "nice" reasons for any sport
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


def _generate_condition_labels(
    sport_key: str,
    metrics: dict[str, float | None],
    context: dict[str, float | None],
    label: str,
    flags: list[str],
) -> dict[str, list[str]]:
    """
    Generate condition labels categorized by color (green, yellow, red).
    Returns dict with keys 'green', 'yellow', 'red' and lists of snake_case label strings.
    """
    green_labels: list[str] = []
    yellow_labels: list[str] = []
    red_labels: list[str] = []
    seen_labels: set[str] = set()
    
    def add_label(category: list[str], label_text: str):
        """Add label if not duplicate (case-insensitive)"""
        normalized = label_text.lower().strip()
        if normalized not in seen_labels:
            seen_labels.add(normalized)
            category.append(label_text)
    
    status = label.lower()
    wave_height = context.get("wave_height_m") or metrics.get("wave_height")
    wave_period = context.get("wave_period_s") or metrics.get("wave_period")
    wind_wave_height = context.get("wind_wave_height_m") or metrics.get("wind_wave_height")
    current_kmh = context.get("current_kmh") or metrics.get("ocean_current_velocity_kmh")
    wind_speed = metrics.get("wind_speed_kmh")
    
    # Wave conditions (for wave sports)
    if sport_key in {"surfing", "sup_surf"}:
        if wave_height is not None and wave_period is not None:
            if wave_height >= 0.5 and wave_period >= 6:
                add_label(green_labels, "great_waves")
            elif wave_height >= 0.3 and wave_period >= 4:
                add_label(green_labels, "good_waves")
                # For OK/Marginal, show why it's not Great
                if status in {"ok", "marginal"}:
                    if wave_height < 0.5 or wave_period < 6:
                        add_label(yellow_labels, "moderate_waves")
            else:
                # Small waves - show as negative for OK/Marginal/Bad
                if status in {"ok", "marginal", "bad"}:
                    add_label(yellow_labels, "small_waves")
        
        # Chop (wind waves)
        if wind_wave_height is not None:
            if wind_wave_height >= 0.5:
                add_label(red_labels, "chop")
            elif wind_wave_height >= 0.3:
                add_label(yellow_labels, "chop")
            elif wind_wave_height >= 0.15:
                # Show moderate chop for OK/Marginal status
                if status in {"ok", "marginal"}:
                    add_label(yellow_labels, "chop")
            elif wind_wave_height < 0.15 and status == "great":
                add_label(green_labels, "low_chop")
    
    # SUP-specific conditions (flatwater/cruising)
    if sport_key == "sup":
        # Wave height
        if wave_height is not None:
            if wave_height >= 0.8:
                add_label(red_labels, "too_wavy")
            elif wave_height > 0.3 and wave_height <= 0.5:
                # OK range - above great_max but within ok_max
                if status in {"ok", "marginal"}:
                    add_label(yellow_labels, "moderate_waves")
            elif wave_height <= 0.3:
                add_label(green_labels, "calm_surface")
        
        # Wind wave height (chop)
        if wind_wave_height is not None:
            if wind_wave_height >= 0.45:
                add_label(red_labels, "too_choppy")
            elif wind_wave_height > 0.15 and wind_wave_height <= 0.25:
                # OK range
                if status in {"ok", "marginal"}:
                    add_label(yellow_labels, "chop")
            elif wind_wave_height <= 0.15:
                add_label(green_labels, "low_chop")
        
        # Current
        if current_kmh is not None:
            if current_kmh >= 5.0:
                add_label(red_labels, "strong_current")
            elif current_kmh >= 2.5 and current_kmh < 5.0:
                # OK range
                if status in {"ok", "marginal"}:
                    add_label(yellow_labels, "current")
            elif current_kmh < 2.5:
                add_label(green_labels, "easy_current")
    
    # SUP Surf conditions
    if sport_key == "sup_surf":
        if current_kmh is not None:
            if current_kmh >= 5:
                add_label(red_labels, "strong_current")
            elif current_kmh >= 3:
                add_label(yellow_labels, "current")
            elif current_kmh <= 3:
                add_label(green_labels, "mild_current")
    
    # Wind conditions (for wind sports)
    if sport_key in {"windsurfing", "kitesurfing"}:
        if wind_speed is not None:
            if wind_speed >= 25:
                add_label(green_labels, "strong_wind")
            elif wind_speed >= 15:
                add_label(green_labels, "good_wind")
            elif wind_speed >= 10 and wind_speed < 15:
                # Moderate wind - OK but not great
                if status in {"ok", "marginal"}:
                    add_label(yellow_labels, "light_wind")
            elif wind_speed < 10:
                add_label(red_labels, "no_wind")
        elif wind_wave_height is not None:
            # Use wind_wave_height as proxy
            if wind_wave_height >= 0.4 and wind_wave_height <= 1.2:
                add_label(green_labels, "good_wind")
            elif wind_wave_height >= 0.25 and wind_wave_height < 0.4:
                # Moderate wind - OK but not great
                if status in {"ok", "marginal"}:
                    add_label(yellow_labels, "light_wind")
            elif wind_wave_height < 0.25:
                add_label(red_labels, "no_wind")
    
    # Current for all sports (show as positive when mild)
    if current_kmh is not None and current_kmh <= 3.0:
        # Only add if not already handled by sport-specific logic above
        if sport_key not in {"sup", "sup_surf"}:
            add_label(green_labels, "mild_current")
    
    # Add flags as red/yellow labels based on severity
    if flags:
        for flag in flags:
            # Determine if flag should be yellow (OK issue) or red (bad issue)
            if status == "bad":
                add_label(red_labels, flag)
            else:
                add_label(yellow_labels, flag)
    
    return {
        "green": green_labels,
        "yellow": yellow_labels,
        "red": red_labels,
    }


def _generate_tips(
    sport_key: str,
    metrics: dict[str, float | None],
    context: dict[str, float | None],
    flags: list[str],
) -> list[dict[str, str]]:
    """
    Generate contextual tips based on conditions.
    Returns 0-3 tips max, only when they matter.
    """
    tips: list[dict[str, str]] = []
    
    # Water temperature → wetsuit recommendation
    # Check both context and metrics (context might be filtered)
    water_temp = context.get("water_temp_c")
    if water_temp is None:
        water_temp = metrics.get("sea_surface_temperature")
    
    # Validate water_temp is a valid number
    if water_temp is not None:
        try:
            water_temp_float = float(water_temp)
            if math.isnan(water_temp_float) or math.isinf(water_temp_float):
                water_temp = None
            else:
                water_temp = water_temp_float
        except (ValueError, TypeError):
            water_temp = None
    
    if water_temp is not None:
        if water_temp >= 24:
            tips.append({
                "id": "wetsuit_warm",
                "severity": "info",
                "icon": "wetsuit",
                "text": f"Water {water_temp:.0f}°C → rashguard / trunks",
            })
        elif water_temp >= 21:
            tips.append({
                "id": "wetsuit_spring",
                "severity": "info",
                "icon": "wetsuit",
                "text": f"Water {water_temp:.0f}°C → spring suit / 2mm top",
            })
        elif water_temp >= 18:
            tips.append({
                "id": "wetsuit_3_2",
                "severity": "info",
                "icon": "wetsuit",
                "text": f"Water {water_temp:.0f}°C → 3/2mm recommended",
            })
        elif water_temp >= 16:
            tips.append({
                "id": "wetsuit_4_3",
                "severity": "info",
                "icon": "wetsuit",
                "text": f"Water {water_temp:.0f}°C → 4/3mm recommended",
            })
        elif water_temp >= 13:
            tips.append({
                "id": "wetsuit_5_4",
                "severity": "info",
                "icon": "wetsuit",
                "text": f"Water {water_temp:.0f}°C → 5/4mm + boots",
            })
        else:
            tips.append({
                "id": "wetsuit_6_5",
                "severity": "info",
                "icon": "wetsuit",
                "text": f"Water {water_temp:.0f}°C → 6/5mm + hood",
            })
    
    # UV index (if available in metrics)
    uv_index = metrics.get("uv_index")
    if uv_index is not None:
        if uv_index >= 8:
            tips.append({
                "id": "uv_high",
                "severity": "warn",
                "icon": "sun",
                "text": "UV high → sunscreen + shade plan",
            })
        elif uv_index >= 6:
            tips.append({
                "id": "uv_moderate",
                "severity": "info",
                "icon": "sun",
                "text": "UV moderate-high → sunscreen recommended",
            })
    
    # Current warnings
    current_kmh = context.get("current_kmh") or metrics.get("ocean_current_velocity_kmh")
    if current_kmh is not None:
        if current_kmh >= 6:
            tips.append({
                "id": "current_strong",
                "severity": "warn",
                "icon": "warning",
                "text": f"Strong current ({current_kmh:.1f} km/h) → avoid solo / stay near shore",
            })
        elif current_kmh >= 4:
            tips.append({
                "id": "current_moderate",
                "severity": "warn",
                "icon": "warning",
                "text": f"Current {current_kmh:.1f} km/h → stay close to shore",
            })
    
    # Wind wave / chop warnings
    wind_wave_h = context.get("wind_wave_height_m") or metrics.get("wind_wave_height")
    if wind_wave_h is not None and wind_wave_h > 0.3:
        tips.append({
            "id": "chop_warning",
            "severity": "info",
            "icon": "waves",
            "text": "Choppy conditions → larger board / beginner warning",
        })
    
    # Keep max 3 tips
    return tips[:3]


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

    # Water temp removed from scoring - now only in context

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

    # Check hard limits
    hard_limits = sport.get("hard_limits", {})
    flags: list[str] = []
    reasons: list[str] = []
    
    if hard_limits:
        limit_flags, limit_reasons = _check_hard_limits(metrics, hard_limits, sport_key)
        flags.extend(limit_flags)
        reasons.extend(limit_reasons)
        
        # If any hard limit violated, force bad label and clamp score
        if limit_flags:
            label = "bad"
            score = min(score, 0.2)  # Clamp score when unsafe
        else:
            label = _label_from_score(score, thresholds)
    else:
        label = _label_from_score(score, thresholds)

    # Add positive reasons if no hard limit violations
    if not flags:
        positive_reasons = _pick_reasons(sport_key, metrics, subscores, flags)
        reasons.extend(positive_reasons)

    # Build context from context_fields
    context: dict[str, float | None] = {}
    context_fields = sport.get("context_fields", [])
    
    # Map context field names to metric keys and format
    for field in context_fields:
        if field == "sea_surface_temperature":
            context["water_temp_c"] = metrics.get("sea_surface_temperature")
        elif field == "wave_height":
            context["wave_height_m"] = metrics.get("wave_height")
        elif field == "wave_period":
            context["wave_period_s"] = metrics.get("wave_period")
        elif field == "wind_wave_height":
            context["wind_wave_height_m"] = metrics.get("wind_wave_height")
        elif field == "ocean_current_velocity":
            context["current_kmh"] = metrics.get("ocean_current_velocity_kmh")
        elif field == "uv_index":
            context["uv_index"] = metrics.get("uv_index")

    # Generate tips (pass full metrics so tips can access all data)
    tips = _generate_tips(sport_key, metrics, context, flags)
    
    # Generate condition labels (categorized by color)
    condition_labels = _generate_condition_labels(sport_key, metrics, context, label, flags)
    
    # Debug: log if tips are empty (remove in production)
    if not tips:
        water_temp_debug = context.get("water_temp_c") or metrics.get("sea_surface_temperature")
        uv_debug = context.get("uv_index") or metrics.get("uv_index")
        current_debug = context.get("current_kmh") or metrics.get("ocean_current_velocity_kmh")
        print(f"DEBUG: No tips for {sport_key} at {hour.get('date', 'unknown')}")
        print(f"  - water_temp: {water_temp_debug}")
        print(f"  - uv_index: {uv_debug}")
        print(f"  - current: {current_debug}")
        print(f"  - context keys: {list(context.keys())}")
        print(f"  - metrics has sea_surface_temperature: {'sea_surface_temperature' in metrics}")
        print(f"  - metrics has uv_index: {'uv_index' in metrics}")

    return {
        "sport": sport_key,
        "date": hour.get("date"),
        "label": label,
        "score": round(score, 3),
        "context": {k: round(v, 2) if v is not None else None for k, v in context.items() if v is not None},
        "flags": flags,
        "reasons": reasons,
        "tips": tips,
        "condition_labels": condition_labels,
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
        # Each sport result now includes date, so we can return flat list or grouped
        # Returning grouped by date for easier consumption
        row = {
            "date": hour.get("date"),
            "sports": {s: score_hour_for_sport(hour, sport_key=s, rules=rules) for s in sports_list},
        }
        out.append(row)
    return out
