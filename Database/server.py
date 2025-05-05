#This is the file that you run to start the server

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from .database import engine, Base
from .routers import users, resources, game_state, data_import, cosmetics, shop, ecns, leaderboard

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

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)

