from fastapi import APIRouter, Depends, File, UploadFile
from typing import Optional

from routes.deps import get_current_user
from services.image_service import analyse_damage, compute_similarity

router = APIRouter(prefix="/images", tags=["images"])


@router.post("/verify")
def verify_images(
    after_image: UploadFile = File(...),
    before_image: Optional[UploadFile] = File(None),
    current_user: dict = Depends(get_current_user),
):
    """
    Standalone image verification endpoint.
    Accepts an after-disaster image and an optional before-image.
    Returns similarity_score and loss_percentage.
    """
    after_bytes = after_image.file.read()

    if before_image:
        before_bytes = before_image.file.read()
        similarity_score = compute_similarity(before_bytes, after_bytes)
    else:
        similarity_score = analyse_damage(after_bytes)

    loss_percentage = round((1.0 - similarity_score) * 100, 1)

    return {
        "similarity_score": similarity_score,
        "loss_percentage": loss_percentage,
    }
