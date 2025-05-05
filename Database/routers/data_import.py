from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
import json
import csv
from .. import models, schemas
from ..database import get_db

router = APIRouter()

@router.post("/import/users")
async def import_users(file: UploadFile = File(...), db: AsyncSession = Depends(get_db)):
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="Only CSV files are supported")
    
    content = await file.read()
    content = content.decode('utf-8')
    
    # Parse CSV
    csv_reader = csv.DictReader(content.splitlines())
    users = []
    
    for row in csv_reader:
        user = models.User(
            id=row.get('id', ''),
            username=row.get('username', ''),
            email=row.get('email', '')
        )
        users.append(user)
    
    # Add users to database
    for user in users:
        db.add(user)
    
    await db.commit()
    return {"message": f"Successfully imported {len(users)} users"}

@router.post("/import/resources")
async def import_resources(file: UploadFile = File(...), db: AsyncSession = Depends(get_db)):
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="Only CSV files are supported")
    
    content = await file.read()
    content = content.decode('utf-8')
    
    # Parse CSV
    csv_reader = csv.DictReader(content.splitlines())
    resources = []
    
    for row in csv_reader:
        resource = models.Resource(
            user_id=row.get('user_id', ''),
            resource_type=row.get('resource_type', ''),
            amount=float(row.get('amount', 0))
        )
        resources.append(resource)
    
    # Add resources to database
    for resource in resources:
        db.add(resource)
    
    await db.commit()
    return {"message": f"Successfully imported {len(resources)} resources"}

@router.post("/import/game_states")
async def import_game_states(file: UploadFile = File(...), db: AsyncSession = Depends(get_db)):
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="Only CSV files are supported")
    
    content = await file.read()
    content = content.decode('utf-8')
    
    # Parse CSV
    csv_reader = csv.DictReader(content.splitlines())
    game_states = []
    
    for row in csv_reader:
        game_state = models.GameState(
            user_id=row.get('user_id', ''),
            current_planet=row.get('current_planet', ''),
            current_level=int(row.get('current_level', 1)),
            score=float(row.get('score', 0))
        )
        game_states.append(game_state)
    
    # Add game states to database
    for game_state in game_states:
        db.add(game_state)
    
    await db.commit()
    return {"message": f"Successfully imported {len(game_states)} game states"}

@router.get("/export/users")
async def export_users(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.User))
    users = result.scalars().all()
    
    # Convert to CSV format
    csv_data = "id,username,email\n"
    for user in users:
        csv_data += f"{user.id},{user.username},{user.email}\n"
    
    return {"data": csv_data}

@router.get("/export/resources")
async def export_resources(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Resource))
    resources = result.scalars().all()
    
    # Convert to CSV format
    csv_data = "user_id,resource_type,amount\n"
    for resource in resources:
        csv_data += f"{resource.user_id},{resource.resource_type},{resource.amount}\n"
    
    return {"data": csv_data}

@router.get("/export/game_states")
async def export_game_states(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.GameState))
    game_states = result.scalars().all()
    
    # Convert to CSV format
    csv_data = "user_id,current_planet,current_level,score\n"
    for game_state in game_states:
        csv_data += f"{game_state.user_id},{game_state.current_planet},{game_state.current_level},{game_state.score}\n"
    
    return {"data": csv_data} 