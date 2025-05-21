#This is the file that you run to start the server

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import Session
from .database import engine, Base, get_db
from .routers import users, resources, game_state, data_import, cosmetics, shop, ecns, leaderboard
from . import models, schemas
import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = FastAPI(title="ECN Game Server")

# Basic CORS setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(users.router, prefix="/api/v1", tags=["users"])
app.include_router(resources.router, prefix="/api/v1", tags=["resources"])
app.include_router(game_state.router, prefix="/api/v1", tags=["game_state"])
app.include_router(data_import.router, prefix="/api/v1", tags=["data_import"])
app.include_router(cosmetics.router, prefix="/api/v1", tags=["cosmetics"])
app.include_router(shop.router, prefix="/api/v1", tags=["shop"])
app.include_router(ecns.router, prefix="/api/v1", tags=["ecns"])
app.include_router(leaderboard.router, prefix="/api/v1", tags=["leaderboard"])

@app.on_event("startup")
async def startup():
    # Create database tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

@app.get("/")
async def root():
    return {"message": "Server is running"}

@app.post("/api/v1/users/", response_model=schemas.User)
async def create_user(user: schemas.UserCreate, db: AsyncSession = Depends(get_db)):
    logger.debug(f"Received user creation request: {user.dict()}")
    
    # Check if user already exists
    existing_user = await db.query(models.User).filter(models.User.id == user.id).first()
    if existing_user:
        logger.warning(f"User {user.id} already exists")
        raise HTTPException(status_code=400, detail="User already exists")
    
    # Create new user
    db_user = models.User(**user.dict())
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    
    logger.info(f"Successfully created user: {user.id}")
    return db_user

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)

