import asyncio
from database import engine, Base
from models import User, Resources, GameState, Cosmetics, ShopItem, ECN, Relationship, PointsAllocation

async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)

if __name__ == "__main__":
    asyncio.run(init_db())
    print("Database initialized successfully!") 