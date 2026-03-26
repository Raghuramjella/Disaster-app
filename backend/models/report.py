from pydantic import BaseModel
from typing import Optional


class ReportResponse(BaseModel):
    id: int
    claim_id: int
    similarity_score: float
    damage_tier: str
    loss_percentage: float
    compensation_amount: float
    pdf_url: Optional[str] = None
    generated_at: str
    # Satellite imagery
    satellite_before_url: Optional[str] = None
    satellite_after_url: Optional[str] = None
    # Photo authenticity
    authenticity_score: Optional[float] = None
    photo_verified: Optional[bool] = None
