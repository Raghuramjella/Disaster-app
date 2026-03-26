"""
Google Earth Engine service.

Fetches Sentinel-2 satellite thumbnails for a given location:
  - get_before_image : image from 1-2 days BEFORE the incident (progressive fallback)
  - get_after_image  : image from 1-2 days AFTER the incident  (progressive fallback)

Search strategy (three tiers, stops as soon as an image is found):
  Tier 1 — incident ±1-2 days   (ideal — closest to the event)
  Tier 2 — incident ±3-7 days   (likely — covers one Sentinel-2 revisit cycle)
  Tier 3 — incident ±8-30 days  (fallback — heavy cloud cover or data gap)

Sentinel-2A + 2B together have a ~5 day global revisit cycle, so Tier 1
succeeds roughly 40% of the time and Tier 2 covers the remaining cases.

Requirements
------------
1. A GEE-enabled Google Cloud service account.
2. `earthengine-api` package  (pip install earthengine-api).
3. GEE_SERVICE_ACCOUNT and GEE_KEY_FILE set in .env.
"""
from datetime import datetime, timedelta
from typing import Optional

import httpx

from config import GEE_KEY_FILE, GEE_SERVICE_ACCOUNT


def _fetch_sentinel(
    latitude: float,
    longitude: float,
    date_start: str,
    date_end: str,
    sort_ascending: bool = False,
) -> Optional[bytes]:
    """
    Internal helper — fetches one Sentinel-2 thumbnail for the given window.
    sort_ascending=False → most recent image first (use for before-image)
    sort_ascending=True  → earliest image first (use for after-image)
    """
    if not GEE_SERVICE_ACCOUNT or not GEE_KEY_FILE:
        return None

    try:
        import ee  # type: ignore

        credentials = ee.ServiceAccountCredentials(GEE_SERVICE_ACCOUNT, GEE_KEY_FILE)
        ee.Initialize(credentials)

        point = ee.Geometry.Point([longitude, latitude])
        region = point.buffer(500).bounds()

        collection = (
            ee.ImageCollection("COPERNICUS/S2_SR_HARMONIZED")
            .filterBounds(point)
            .filterDate(date_start, date_end)
            .filter(ee.Filter.lt("CLOUDY_PIXEL_PERCENTAGE", 20))
            .filter(ee.Filter.gt("system:asset_size", 0))
        )

        # Pick closest image to the incident date
        if sort_ascending:
            image = collection.sort("system:time_start").first()
        else:
            image = collection.sort("system:time_start", False).first()

        image = image.select(["B4", "B3", "B2"])  # RGB bands

        thumb_url: str = image.getThumbURL(
            {
                "min": 0,
                "max": 3000,
                "dimensions": 256,
                "region": region,
                "format": "jpg",
            }
        )

        response = httpx.get(thumb_url, timeout=30)
        if response.status_code == 200:
            return response.content

    except Exception as exc:
        print(f"[GEE] Could not fetch satellite image ({date_start} → {date_end}): {exc}")

    return None


def get_before_image(
    latitude: float,
    longitude: float,
    date_before: str,  # ISO date string of the incident, e.g. "2024-06-15"
) -> Optional[bytes]:
    """
    Return JPEG bytes of the Sentinel-2 image taken 1-2 days before the incident.
    Falls back to wider windows if no cloud-free pass exists that close.

    Tier 1: incident-2  → incident-1   (1-2 days before — ideal)
    Tier 2: incident-7  → incident-3   (3-7 days before — one revisit cycle)
    Tier 3: incident-30 → incident-8   (8-30 days before — last resort)
    """
    incident = datetime.strptime(date_before, "%Y-%m-%d")
    d = lambda n: (incident - timedelta(days=n)).strftime("%Y-%m-%d")

    result = _fetch_sentinel(latitude, longitude, d(2), d(1), sort_ascending=False)
    if result:
        print("[GEE] Before image: found in tier-1 (1-2 days before)")
        return result

    print("[GEE] Before tier-1 empty, trying tier-2 (3-7 days before)")
    result = _fetch_sentinel(latitude, longitude, d(7), d(3), sort_ascending=False)
    if result:
        return result

    print("[GEE] Before tier-2 empty, trying tier-3 (8-30 days before)")
    return _fetch_sentinel(latitude, longitude, d(30), d(8), sort_ascending=False)


def get_after_image(
    latitude: float,
    longitude: float,
    date_after: str,  # ISO date string of the incident, e.g. "2024-06-15"
) -> Optional[bytes]:
    """
    Return JPEG bytes of the Sentinel-2 image taken 1-2 days after the incident.
    Falls back to wider windows if no cloud-free pass exists that close.

    Tier 1: incident+1 → incident+2   (1-2 days after — ideal)
    Tier 2: incident+3 → incident+7   (3-7 days after — one revisit cycle)
    Tier 3: incident+8 → incident+30  (8-30 days after — last resort)
    """
    incident = datetime.strptime(date_after, "%Y-%m-%d")
    d = lambda n: (incident + timedelta(days=n)).strftime("%Y-%m-%d")

    result = _fetch_sentinel(latitude, longitude, d(1), d(2), sort_ascending=True)
    if result:
        print("[GEE] After image: found in tier-1 (1-2 days after)")
        return result

    print("[GEE] After tier-1 empty, trying tier-2 (3-7 days after)")
    result = _fetch_sentinel(latitude, longitude, d(3), d(7), sort_ascending=True)
    if result:
        return result

    print("[GEE] After tier-2 empty, trying tier-3 (8-30 days after)")
    return _fetch_sentinel(latitude, longitude, d(8), d(30), sort_ascending=True)
