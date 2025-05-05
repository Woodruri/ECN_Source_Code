from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from .. import models, schemas
from ..database import get_db

router = APIRouter()

@router.get("/game_state/planet/{planet_id}", response_model=List[str])
async def get_rockets_on_planet(planet_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.GameState).where(models.GameState.current_planet == planet_id)
    )
    game_states = result.scalars().all()
    return [state.user_id for state in game_states]

@router.get("/users/{user_id}/game_state", response_model=schemas.GameState)
async def get_user_game_state(user_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.GameState).where(models.GameState.user_id == user_id)
    )
    game_state = result.scalar_one_or_none()
    
    if game_state is None:
        # Create default game state if none exists
        game_state = models.GameState(
            user_id=user_id,
            current_planet="Planet_1",
            current_level=1,
            score=0
        )
        db.add(game_state)
        await db.commit()
        await db.refresh(game_state)
    
    return game_state

@router.post("/users/{user_id}/game_state", response_model=schemas.GameState)
async def update_game_state(
    user_id: str,
    game_state: schemas.GameStateCreate,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(models.GameState).where(models.GameState.user_id == user_id)
    )
    existing_state = result.scalar_one_or_none()
    
    if existing_state is None:
        # Create new game state
        db_game_state = models.GameState(
            user_id=user_id,
            current_planet=game_state.current_planet,
            current_level=game_state.current_level,
            score=game_state.score
        )
        db.add(db_game_state)
    else:
        # Update existing game state
        existing_state.current_planet = game_state.current_planet
        existing_state.current_level = game_state.current_level
        existing_state.score = game_state.score
        db_game_state = existing_state
    
    await db.commit()
    await db.refresh(db_game_state)
    return db_game_state 