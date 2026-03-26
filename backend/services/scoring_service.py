"""
Damage scoring service.

Maps a similarity score (0.0–1.0) to a damage tier and calculates
the estimated compensation amount.

Tier thresholds (based on similarity score):
  90–100% similar → No Loss   (0% compensation)
  75–90%          → Minor     (15%)
  50–75%          → Moderate  (40%)
  25–50%          → High      (70%)
  10–25%          → Severe    (90%)
   0–10%          → Total Loss (100%)
"""
from typing import Tuple

# (similarity lower bound, tier name, compensation multiplier)
# Evaluated highest-first; first matching tier wins.
_TIERS = [
    (0.90, "No Loss",    0.00),
    (0.75, "Minor",      0.15),
    (0.50, "Moderate",   0.40),
    (0.25, "High",       0.70),
    (0.10, "Severe",     0.90),
    (0.00, "Total Loss", 1.00),
]


def compute_damage(
    similarity_score: float,
    property_value: float,
) -> Tuple[str, float, float]:
    """
    Returns (damage_tier, loss_percentage, compensation_amount).

    similarity_score : float in [0.0, 1.0]
        1.0 = identical images (no damage), 0.0 = completely different (total loss)
    property_value : float
        Declared property value in ₹
    """
    loss_percentage = round((1.0 - similarity_score) * 100, 1)

    damage_tier = "Total Loss"
    multiplier = 1.00
    for threshold, tier, mult in _TIERS:
        if similarity_score >= threshold:
            damage_tier = tier
            multiplier = mult
            break

    compensation_amount = round(property_value * multiplier, 2)
    return damage_tier, loss_percentage, compensation_amount
