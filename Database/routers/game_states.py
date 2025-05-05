from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from database import get_db
from models import GameState
from sqlalchemy import select
from typing import List

router = APIRouter()

@router.get("/game-states/{user_id}")
async def get_game_state(user_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(GameState).where(GameState.user_id == user_id))
    game_state = result.scalar_one_or_none()
    if game_state is None:
        raise HTTPException(status_code=404, detail="Game state not found")
    return game_state

@router.post("/game-states/")
async def create_game_state(game_state: GameState, db: AsyncSession = Depends(get_db)):
    db.add(game_state)
    await db.commit()
    await db.refresh(game_state)
    return game_state

@router.put("/game-states/{user_id}")
async def update_game_state(user_id: str, game_state_data: dict, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(GameState).where(GameState.user_id == user_id))
    game_state = result.scalar_one_or_none()
    if game_state is None:
        raise HTTPException(status_code=404, detail="Game state not found")
    
    for key, value in game_state_data.items():
        setattr(game_state, key, value)
    
    await db.commit()
    await db.refresh(game_state)
    return game_state 