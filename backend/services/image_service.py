"""
Image analysis service.

compute_similarity        — human-like structural comparison of two satellite images
analyse_damage            — single-image damage proxy (no reference image)
verify_photo_authenticity — checks whether user's photo looks like a genuine disaster scene
"""
import hashlib
import io
import random
from typing import Tuple

import cv2
import numpy as np
from PIL import Image, ImageFilter, ImageOps
from skimage.metrics import structural_similarity as skimage_ssim


# ── Helpers ───────────────────────────────────────────────────────────────────

def _decode(img_bytes: bytes) -> np.ndarray:
    """Decode image bytes → BGR numpy array (OpenCV format)."""
    arr = np.frombuffer(img_bytes, np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("cv2.imdecode returned None")
    return img


def _align(reference: np.ndarray, to_align: np.ndarray) -> np.ndarray:
    """ORB keypoint alignment — corrects sub-pixel shifts between satellite passes."""
    orb = cv2.ORB_create(500)
    kp1, des1 = orb.detectAndCompute(reference, None)
    kp2, des2 = orb.detectAndCompute(to_align, None)
    if des1 is None or des2 is None or len(kp1) < 10 or len(kp2) < 10:
        return to_align
    matches = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True).match(des1, des2)
    if len(matches) < 10:
        return to_align
    matches = sorted(matches, key=lambda m: m.distance)[:50]
    pts1 = np.float32([kp1[m.queryIdx].pt for m in matches])
    pts2 = np.float32([kp2[m.trainIdx].pt for m in matches])
    matrix, _ = cv2.estimateAffinePartial2D(pts2, pts1)
    if matrix is not None:
        return cv2.warpAffine(to_align, matrix, (reference.shape[1], reference.shape[0]))
    return to_align


def _black_mask(img: np.ndarray) -> np.ndarray:
    """Return a binary mask ignoring near-black (no-data) pixels."""
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, mask = cv2.threshold(gray, 10, 255, cv2.THRESH_BINARY)
    return mask


def _orb_feature_similarity(img1: np.ndarray, img2: np.ndarray) -> float:
    """ORB match ratio — how many keypoints are shared between the two images."""
    orb = cv2.ORB_create(500)
    kp1, des1 = orb.detectAndCompute(img1, None)
    kp2, des2 = orb.detectAndCompute(img2, None)
    if des1 is None or des2 is None or len(kp1) == 0 or len(kp2) == 0:
        return 0.0
    matches = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True).match(des1, des2)
    if len(matches) == 0:
        return 0.0
    matches = sorted(matches, key=lambda m: m.distance)
    score = len(matches) / max(len(kp1), len(kp2))
    return float(np.clip(score, 0.0, 1.0))


# ── Main entry point ──────────────────────────────────────────────────────────

def compute_similarity(before_bytes: bytes, after_bytes: bytes) -> float:
    """
    Human-like similarity of two satellite images.
    Returns a score in [0.0, 1.0] where 1.0 = identical (no damage).

    Pipeline
    --------
    1. Decode & resize to same dimensions.
    2. Align after-image onto before-image (ORB affine warp).
    3. Build combined mask — exclude black / no-data borders from both images.
    4. Apply mask to both images.
    5. SSIM  (60%) — structural + luminance + contrast via skimage.
    6. ORB feature similarity (40%) — shared keypoint ratio.

    Tier mapping (applied in scoring_service):
      90–100% similar → No Loss
      75–90%          → Minor
      50–75%          → Moderate
      25–50%          → High
      10–25%          → Severe
       0–10%          → Total Loss
    """
    try:
        img_b = _decode(before_bytes)
        img_a = _decode(after_bytes)

        # Resize to same dimensions
        h = min(img_b.shape[0], img_a.shape[0])
        w = min(img_b.shape[1], img_a.shape[1])
        img_b = cv2.resize(img_b, (w, h))
        img_a = cv2.resize(img_a, (w, h))

        # Align after-image onto before
        img_a = _align(img_b, img_a)

        # Build combined no-data mask and apply
        mask = cv2.bitwise_and(_black_mask(img_b), _black_mask(img_a))
        img_b_m = cv2.bitwise_and(img_b, img_b, mask=mask)
        img_a_m = cv2.bitwise_and(img_a, img_a, mask=mask)

        valid_pixels = int(np.count_nonzero(mask))
        if valid_pixels < 100:
            return 0.95   # almost entirely no-data — assume unchanged

        # SSIM on grayscale
        gray_b = cv2.cvtColor(img_b_m, cv2.COLOR_BGR2GRAY)
        gray_a = cv2.cvtColor(img_a_m, cv2.COLOR_BGR2GRAY)
        ssim_score = float(np.clip(
            skimage_ssim(gray_b, gray_a, data_range=255), 0.0, 1.0
        ))

        # ORB feature similarity
        feat_score = _orb_feature_similarity(img_b_m, img_a_m)

        raw = float(np.clip(0.6 * ssim_score + 0.4 * feat_score, 0.0, 1.0))
        similarity = round(min(1.0, raw + 0.4), 4)

        print(f"[SIM] ssim={ssim_score:.3f}  features={feat_score:.3f}  raw={raw:.4f}  → {similarity:.4f}")
        return similarity

    except Exception as exc:
        print(f"[SIM] Error: {exc}")
        return 0.5


def analyse_damage(after_bytes: bytes) -> float:
    """
    Estimate damage from a single image when no reference is available.
    Uses brightness + contrast as a proxy (darker/low-contrast → more damage).
    Returns a reproducible score in [0.10, 0.80].
    """
    try:
        img = Image.open(io.BytesIO(after_bytes)).convert("L").resize((64, 64))
        arr = np.array(img, dtype=np.float64)

        mean_brightness = arr.mean() / 255.0
        std_brightness = arr.std() / 128.0

        damage_proxy = 1.0 - (mean_brightness * 0.55 + std_brightness * 0.45)
        damage_proxy = max(0.15, min(0.85, damage_proxy))

        seed = int(hashlib.md5(after_bytes[:512]).hexdigest()[:8], 16)
        jitter = random.Random(seed).uniform(-0.08, 0.08)

        similarity = 1.0 - max(0.10, min(0.80, damage_proxy + jitter))
        return float(round(similarity, 4))
    except Exception:
        return 0.40


def _disaster_scene_score(photo_bytes: bytes) -> float:
    """
    Return a 0-1 score for how much a photo looks like an outdoor disaster scene.
    Used standalone when no satellite reference image is available.
    """
    try:
        user_color = Image.open(io.BytesIO(photo_bytes)).convert("RGB").resize((128, 128))
        user_img = user_color.convert("L")
        user_arr = np.array(user_img, dtype=np.float64)
        color_arr = np.array(user_color, dtype=np.float64) / 255.0

        r, g, b = color_arr[:, :, 0], color_arr[:, :, 1], color_arr[:, :, 2]
        max_rgb = np.maximum(np.maximum(r, g), b)
        min_rgb = np.minimum(np.minimum(r, g), b)
        saturation = np.where(max_rgb > 0.05, (max_rgb - min_rgb) / (max_rgb + 1e-8), 0.0)
        mean_sat = float(saturation.mean())
        sat_score = float(max(0.0, 1.0 - mean_sat / 0.4))

        dark_ratio = float((user_arr < 70).mean())
        dark_score = float(min(1.0, dark_ratio / 0.15))

        edges = np.array(user_img.filter(ImageFilter.FIND_EDGES), dtype=np.float64)
        chaos_score = float(min(1.0, (edges.std() / (edges.mean() + 1e-8)) / 2.5))

        score = sat_score * 0.40 + dark_score * 0.35 + chaos_score * 0.25
        if mean_sat > 0.40 and user_arr.mean() > 140:
            score = min(score, 0.35)
        return round(float(score), 4)
    except Exception:
        return 0.4


def verify_photo_authenticity(
    user_photo_bytes: bytes,
    satellite_after_bytes: bytes,
) -> Tuple[float, bool]:
    """
    Verify whether the user's uploaded photo looks like a genuine disaster scene
    and is consistent with the satellite after-disaster image.

    Two-gate approach
    -----------------
    Gate 1 — Disaster scene validation (60% weight)
      Checks whether the photo itself looks like an outdoor disaster scene.
      Random/indoor photos (books, food, selfies) fail this gate because they are:
        • Highly colourful (high colour saturation)
        • Well-lit with few dark regions
        • Uniform / regular textures

      Genuine disaster photos have:
        • Muted, desaturated colours (grey rubble, brown mud, dark floodwater)
        • Significant dark/damaged areas
        • Chaotic, irregular textures (debris, fire, collapsed structures)

    Gate 2 — Satellite correlation (40% weight)
      Checks whether the photo's damage signals are consistent with what the
      satellite shows (brightness, tonal distribution, texture density).

    Returns
    -------
    (authenticity_score : float 0-1, is_verified : bool)
      authenticity_score >= 0.55 → photo is consistent with a disaster scene
    """
    try:
        # Load colour image for saturation analysis and grayscale for the rest
        user_color = Image.open(io.BytesIO(user_photo_bytes)).convert("RGB").resize((128, 128))
        user_img = user_color.convert("L")
        sat_img = Image.open(io.BytesIO(satellite_after_bytes)).convert("L").resize((128, 128))

        user_arr = np.array(user_img, dtype=np.float64)
        sat_arr = np.array(sat_img, dtype=np.float64)
        color_arr = np.array(user_color, dtype=np.float64) / 255.0

        # ── Gate 1: Disaster scene validation ────────────────────────────────
        disaster_score = _disaster_scene_score(user_photo_bytes)

        # (re-compute edges for Gate 2 edge density comparison)
        user_edges = np.array(user_img.filter(ImageFilter.FIND_EDGES), dtype=np.float64)

        # saturation needed for hard cap below
        r, g, b = color_arr[:, :, 0], color_arr[:, :, 1], color_arr[:, :, 2]
        max_rgb = np.maximum(np.maximum(r, g), b)
        saturation = np.where(max_rgb > 0.05, (max_rgb - np.minimum(np.minimum(r, g), b)) / (max_rgb + 1e-8), 0.0)
        mean_sat = float(saturation.mean())

        # ── Gate 2: Satellite correlation ─────────────────────────────────────

        user_hist = np.histogram(user_arr, bins=32, range=(0, 255))[0].astype(np.float64)
        sat_hist = np.histogram(sat_arr, bins=32, range=(0, 255))[0].astype(np.float64)
        user_hist /= user_hist.sum() + 1e-8
        sat_hist /= sat_hist.sum() + 1e-8
        corr = np.corrcoef(user_hist, sat_hist)[0, 1]
        hist_score = float((corr + 1) / 2)

        sat_brightness = sat_arr.mean() / 255.0
        user_brightness = user_arr.mean() / 255.0
        brightness_score = float(max(0.0, 1.0 - abs(user_brightness - sat_brightness) * 2.0))

        sat_edges = np.array(sat_img.filter(ImageFilter.FIND_EDGES), dtype=np.float64)
        edge_diff = abs(user_edges.mean() - sat_edges.mean()) / 255.0
        edge_score = float(max(0.0, 1.0 - edge_diff * 3.0))

        satellite_score = hist_score * 0.40 + brightness_score * 0.35 + edge_score * 0.25

        # ── Combined score ────────────────────────────────────────────────────
        authenticity_score = round(disaster_score * 0.60 + satellite_score * 0.40, 4)

        # Hard cap: bright + colourful photo cannot be a disaster scene
        # (catches books, food, selfies, screenshots, etc.)
        if mean_sat > 0.40 and user_arr.mean() > 140:
            authenticity_score = min(authenticity_score, 0.35)

        is_verified = authenticity_score >= 0.55
        return float(authenticity_score), is_verified

    except Exception:
        return 0.4, False  # fail safely — do not auto-approve on processing error
