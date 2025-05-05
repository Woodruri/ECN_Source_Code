from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import declarative_base, sessionmaker
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# Get database URL from environment variable or use default SQLite
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./ecn_game.db")

# Create async engine
engine = create_async_engine(DATABASE_URL, echo=True)

# Create async session factory
SessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

# Create base class for models
Base = declarative_base()

# Dependency to get DB session
async def get_db():
    async with SessionLocal() as session:
        try:
            yield session
        finally:
            await session.close() 