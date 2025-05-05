from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from pydantic import BaseModel, Field
from ..database import get_db
from ..models import ShopItem

router = APIRouter(prefix="/shop", tags=["shop"])

class ShopItemBase(BaseModel):
    item_type: str = Field(..., description="Type of the item")
    item_id: str = Field(..., description="Unique identifier for the item")
    price: int = Field(..., description="Price of the item in game currency")
    is_available: bool = Field(default=True, description="Whether the item is available for purchase")

class ShopItemCreate(ShopItemBase):
    pass

class ShopItemResponse(ShopItemBase):
    id: str = Field(..., description="Database ID of the item")

    class Config:
        from_attributes = True

class PurchaseRequest(BaseModel):
    user_id: str = Field(..., description="ID of the user making the purchase")
    item_id: str = Field(..., description="ID of the item to purchase")

class PurchaseResponse(BaseModel):
    success: bool = Field(..., description="Whether the purchase was successful")
    message: str = Field(..., description="Message describing the result of the purchase")

@router.get("/items", response_model=List[ShopItemResponse])
async def get_shop_items(
    db: AsyncSession = Depends(get_db),
    available_only: bool = True
) -> List[ShopItemResponse]:
    """
    Get all shop items.
    
    Args:
        available_only: If True, only return items that are available for purchase
        db: Database session
    
    Returns:
        List of shop items
    """
    query = select(ShopItem)
    if available_only:
        query = query.where(ShopItem.is_available == True)
    
    result = await db.execute(query)
    items = result.scalars().all()
    return items

@router.get("/items/{item_id}", response_model=ShopItemResponse)
async def get_shop_item(
    item_id: str,
    db: AsyncSession = Depends(get_db)
) -> ShopItemResponse:
    """
    Get a specific shop item by ID.
    
    Args:
        item_id: ID of the item to retrieve
        db: Database session
    
    Returns:
        Shop item details
    
    Raises:
        HTTPException: If item is not found
    """
    result = await db.execute(select(ShopItem).where(ShopItem.id == item_id))
    item = result.scalar_one_or_none()
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return item

@router.post("/items", response_model=ShopItemResponse, status_code=201)
async def create_shop_item(
    item: ShopItemCreate,
    db: AsyncSession = Depends(get_db)
) -> ShopItemResponse:
    """
    Create a new shop item.
    
    Args:
        item: Item data to create
        db: Database session
    
    Returns:
        Created shop item
    """
    db_item = ShopItem(**item.model_dump())
    db.add(db_item)
    await db.commit()
    await db.refresh(db_item)
    return db_item

@router.put("/items/{item_id}", response_model=ShopItemResponse)
async def update_shop_item(
    item_id: str,
    item_data: ShopItemCreate,
    db: AsyncSession = Depends(get_db)
) -> ShopItemResponse:
    """
    Update an existing shop item.
    
    Args:
        item_id: ID of the item to update
        item_data: New item data
        db: Database session
    
    Returns:
        Updated shop item
    
    Raises:
        HTTPException: If item is not found
    """
    result = await db.execute(select(ShopItem).where(ShopItem.id == item_id))
    item = result.scalar_one_or_none()
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    
    for key, value in item_data.model_dump().items():
        setattr(item, key, value)
    
    await db.commit()
    await db.refresh(item)
    return item

@router.post("/purchase", response_model=PurchaseResponse)
async def purchase_item(
    purchase: PurchaseRequest,
    db: AsyncSession = Depends(get_db)
) -> PurchaseResponse:
    """
    Purchase an item from the shop.
    
    Args:
        purchase: Purchase request containing user_id and item_id
        db: Database session
    
    Returns:
        Purchase result
    
    Raises:
        HTTPException: If item is not found or not available
    """
    # Get the item
    result = await db.execute(select(ShopItem).where(ShopItem.id == purchase.item_id))
    item = result.scalar_one_or_none()
    
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    
    if not item.is_available:
        raise HTTPException(status_code=400, detail="Item is not available for purchase")
    
    # TODO: Implement actual purchase logic:
    # 1. Check user's balance
    # 2. Deduct price from user's balance
    # 3. Add item to user's inventory
    # 4. Update item availability if needed
    
    return PurchaseResponse(
        success=True,
        message="Item purchased successfully"
    ) 