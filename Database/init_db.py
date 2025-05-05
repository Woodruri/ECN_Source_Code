import sys
import os

# Add the project root to Python path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(project_root)

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from Database.models import User, Resource, GameState, Cosmetic, ShopItem, ECN, Relationship, PointsAllocation
from Database.database import Base

# Create database engine
engine = create_engine('sqlite:///ecn_game.db')

# Create all tables
Base.metadata.create_all(engine)

print("Database initialized successfully!") 