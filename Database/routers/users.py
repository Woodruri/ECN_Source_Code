from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from ..database import SessionLocal
from ..models import User
from ..schemas import UserCreate, User as UserSchema
from sqlalchemy import select
from .. import models, schemas
from ..database import get_db
from pydantic import BaseModel, Field
from typing import Optional

router = APIRouter(prefix="/users", tags=["users"])

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class UserBase(BaseModel):
    name: str = Field(..., description="User's display name")
    user_id: str = Field(..., description="Unique identifier for the user")
    rank: int = Field(default=1, description="User's rank")
    points: int = Field(default=0, description="User's points")
    resources: dict = Field(default_factory=lambda: {"gas": 0, "scrap": 0}, description="User's resources")

class UserCreate(UserBase):
    pass

class UserResponse(UserBase):
    id: str = Field(..., description="Database ID of the user")

    class Config:
        from_attributes = True

@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(
    user: UserCreate,
    db: AsyncSession = Depends(get_db)
) -> UserResponse:
    """
    Create a new user.
    
    Args:
        user: User data to create
        db: Database session
    
    Returns:
        Created user
    
    Raises:
        HTTPException: If user with same ID already exists
    """
    # Check if user already exists
    result = await db.execute(select(User).where(User.user_id == user.user_id))
    existing_user = result.scalar_one_or_none()
    if existing_user:
        raise HTTPException(status_code=400, detail="User with this ID already exists")
    
    # Create new user
    db_user = User(**user.model_dump())
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    return db_user

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: str,
    db: AsyncSession = Depends(get_db)
) -> UserResponse:
    """
    Get a specific user by ID.
    
    Args:
        user_id: ID of the user to retrieve
        db: Database session
    
    Returns:
        User details
    
    Raises:
        HTTPException: If user is not found
    """
    result = await db.execute(select(User).where(User.user_id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("/{user_id}/game_state", response_model=schemas.GameState)
async def get_user_game_state(user_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.get(models.GameState, user_id)
    if result is None:
        raise HTTPException(status_code=404, detail="Game state not found")
    return result

@router.post("/{user_id}/game_state", response_model=schemas.GameState)
async def update_game_state(
    user_id: str,
    game_state: schemas.GameStateCreate,
    db: AsyncSession = Depends(get_db)
):
    db_game_state = models.GameState(
        user_id=user_id,
        current_planet=game_state.current_planet,
        current_level=game_state.current_level,
        score=game_state.score
    )
    db.add(db_game_state)
    await db.commit()
    await db.refresh(db_game_state)
    return db_game_state

@router.get("/", response_model=List[UserSchema])
async def get_users(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User))
    users = result.scalars().all()
    return users

@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: str,
    user_data: UserCreate,
    db: AsyncSession = Depends(get_db)
) -> UserResponse:
    """
    Update an existing user.
    
    Args:
        user_id: ID of the user to update
        user_data: New user data
        db: Database session
    
    Returns:
        Updated user
    
    Raises:
        HTTPException: If user is not found
    """
    result = await db.execute(select(User).where(User.user_id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    for key, value in user_data.model_dump().items():
        setattr(user, key, value)
    
    await db.commit()
    await db.refresh(user)
    return user 