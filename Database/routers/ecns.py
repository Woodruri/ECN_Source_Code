from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from pydantic import BaseModel, Field
from ..database import get_db
from ..models import ECN

router = APIRouter(prefix="/ecns", tags=["ecns"])

class ECNBase(BaseModel):
    ecn_type: str = Field(..., description="Type of the ECN")
    ecn_id: str = Field(..., description="Unique identifier for the ECN")
    user_id: str = Field(..., description="ID of the user who owns this ECN")
    is_active: bool = Field(default=True, description="Whether the ECN is active")

class ECNCreate(ECNBase):
    pass

class ECNResponse(ECNBase):
    id: str = Field(..., description="Database ID of the ECN")

    class Config:
        from_attributes = True

class SubmitECNRequest(BaseModel):
    user_id: str = Field(..., description="ID of the user submitting the ECN")
    ecn_id: str = Field(..., description="ID of the ECN being submitted")

class SubmitECNResponse(BaseModel):
    success: bool = Field(..., description="Whether the submission was successful")
    message: str = Field(..., description="Message describing the result of the submission")

@router.get("/users/{user_id}/ecns", response_model=List[ECNResponse])
async def get_user_ecns(
    user_id: str,
    db: AsyncSession = Depends(get_db)
) -> List[ECNResponse]:
    """
    Get all ECNs for a specific user.
    
    Args:
        user_id: ID of the user
        db: Database session
    
    Returns:
        List of user's ECNs
    """
    result = await db.execute(select(ECN).where(ECN.user_id == user_id))
    return result.scalars().all()

@router.get("/{ecn_id}", response_model=ECNResponse)
async def get_ecn(
    ecn_id: str,
    db: AsyncSession = Depends(get_db)
) -> ECNResponse:
    """
    Get a specific ECN by ID.
    
    Args:
        ecn_id: ID of the ECN to retrieve
        db: Database session
    
    Returns:
        ECN details
    
    Raises:
        HTTPException: If ECN is not found
    """
    result = await db.execute(select(ECN).where(ECN.id == ecn_id))
    ecn = result.scalar_one_or_none()
    if ecn is None:
        raise HTTPException(status_code=404, detail="ECN not found")
    return ecn

@router.post("/", response_model=ECNResponse, status_code=201)
async def create_ecn(
    ecn: ECNCreate,
    db: AsyncSession = Depends(get_db)
) -> ECNResponse:
    """
    Create a new ECN.
    
    Args:
        ecn: ECN data to create
        db: Database session
    
    Returns:
        Created ECN
    """
    db_ecn = ECN(**ecn.model_dump())
    db.add(db_ecn)
    await db.commit()
    await db.refresh(db_ecn)
    return db_ecn

@router.put("/{ecn_id}", response_model=ECNResponse)
async def update_ecn(
    ecn_id: str,
    ecn_data: ECNCreate,
    db: AsyncSession = Depends(get_db)
) -> ECNResponse:
    """
    Update an existing ECN.
    
    Args:
        ecn_id: ID of the ECN to update
        ecn_data: New ECN data
        db: Database session
    
    Returns:
        Updated ECN
    
    Raises:
        HTTPException: If ECN is not found
    """
    result = await db.execute(select(ECN).where(ECN.id == ecn_id))
    ecn = result.scalar_one_or_none()
    if ecn is None:
        raise HTTPException(status_code=404, detail="ECN not found")
    
    for key, value in ecn_data.model_dump().items():
        setattr(ecn, key, value)
    
    await db.commit()
    await db.refresh(ecn)
    return ecn

@router.post("/submit", response_model=SubmitECNResponse)
async def submit_ecn(
    request: SubmitECNRequest,
    db: AsyncSession = Depends(get_db)
) -> SubmitECNResponse:
    """
    Submit an ECN for processing.
    
    Args:
        request: Submission request containing user_id and ecn_id
        db: Database session
    
    Returns:
        Submission result
    
    Raises:
        HTTPException: If ECN is not found or not active
    """
    # Get the ECN
    result = await db.execute(select(ECN).where(ECN.id == request.ecn_id))
    ecn = result.scalar_one_or_none()
    
    if ecn is None:
        raise HTTPException(status_code=404, detail="ECN not found")
    
    if not ecn.is_active:
        raise HTTPException(status_code=400, detail="ECN is not active")
    
    # TODO: Implement actual submission logic:
    # 1. Update ECN status
    # 2. Update user's points/resources
    # 3. Handle any other submission requirements
    
    return SubmitECNResponse(
        success=True,
        message="ECN submitted successfully"
    ) 