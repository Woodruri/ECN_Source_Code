from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from .. import models, schemas
from ..database import get_db

router = APIRouter()

@router.get("/users/{user_id}/resources", response_model=List[schemas.Resource])
async def get_user_resources(user_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.Resource).where(models.Resource.user_id == user_id)
    )
    resources = result.scalars().all()
    return resources

@router.post("/users/{user_id}/resources", response_model=schemas.Resource)
async def update_resource(
    user_id: str,
    resource: schemas.ResourceCreate,
    db: AsyncSession = Depends(get_db)
):
    db_resource = models.Resource(
        user_id=user_id,
        resource_type=resource.resource_type,
        amount=resource.amount
    )
    db.add(db_resource)
    await db.commit()
    await db.refresh(db_resource)
    return db_resource

@router.put("/users/{user_id}/resources/{resource_type}", response_model=schemas.Resource)
async def update_resource_amount(
    user_id: str,
    resource_type: str,
    amount: float,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(models.Resource).where(
            models.Resource.user_id == user_id,
            models.Resource.resource_type == resource_type
        )
    )
    resource = result.scalar_one_or_none()
    
    if resource is None:
        raise HTTPException(status_code=404, detail="Resource not found")
    
    resource.amount = amount
    await db.commit()
    await db.refresh(resource)
    return resource 