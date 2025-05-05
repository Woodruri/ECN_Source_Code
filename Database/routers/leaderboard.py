from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from ..database import get_db
from ..models import User, GameState
from sqlalchemy import select, func
from typing import List

router = APIRouter()

@router.get("/leaderboard/global")
async def get_global_leaderboard(limit: int = 10, db: AsyncSession = Depends(get_db)):
    # Get users ordered by score
    result = await db.execute(
        select(User, GameState.score)
        .join(GameState)
        .order_by(GameState.score.desc())
        .limit(limit)
    )
    entries = result.all()
    
    return {
        "entries": [
            {
                "id": user.id,
                "name": user.username,
                "points": score,
                "rank": i + 1
            }
            for i, (user, score) in enumerate(entries)
        ]
    }

@router.get("/leaderboard/planet/{planet_id}")
async def get_planet_leaderboard(planet_id: str, limit: int = 10, db: AsyncSession = Depends(get_db)):
    # Get users on specific planet ordered by score
    result = await db.execute(
        select(User, GameState.score)
        .join(GameState)
        .where(GameState.current_planet == planet_id)
        .order_by(GameState.score.desc())
        .limit(limit)
    )
    entries = result.all()
    
    return {
        "entries": [
            {
                "id": user.id,
                "name": user.username,
                "points": score,
                "rank": i + 1
            }
            for i, (user, score) in enumerate(entries)
        ]
    } 