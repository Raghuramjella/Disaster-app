from pydantic import BaseModel
from typing import Optional


class ClaimResponse(BaseModel):
    id: int
    disaster_type: str
    location: str
    description: str
    status: str
    submitted_at: str
    after_image_url: Optional[str] = None
