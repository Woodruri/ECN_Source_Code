from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from ..database import get_db
from ..models import Cosmetic
from sqlalchemy import select
from typing import List

router = APIRouter()

@router.get("/users/{user_id}/cosmetics")
async def get_user_cosmetics(user_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Cosmetic).where(Cosmetic.user_id == user_id))
    cosmetics = result.scalars().all()
    return {"cosmetics": [{"type": c.cosmetic_type, "id": c.cosmetic_id, "equipped": c.is_equipped} for c in cosmetics]}

@router.put("/users/{user_id}/cosmetics")
async def update_user_cosmetics(user_id: str, cosmetics: List[dict], db: AsyncSession = Depends(get_db)):
    # Delete existing cosmetics
    await db.execute(select(Cosmetic).where(Cosmetic.user_id == user_id))
    await db.commit()
    
    # Add new cosmetics
    for cosmetic in cosmetics:
        new_cosmetic = Cosmetic(
            user_id=user_id,
            cosmetic_type=cosmetic["type"],
            cosmetic_id=cosmetic["id"],
            is_equipped=cosmetic.get("equipped", False)
        )
        db.add(new_cosmetic)
    
    await db.commit()
    return {"message": "Cosmetics updated successfully"} 