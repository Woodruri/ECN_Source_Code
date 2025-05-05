from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class UserBase(BaseModel):
    username: str
    email: str

class UserCreate(UserBase):
    pass

class User(UserBase):
    id: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class ResourceBase(BaseModel):
    resource_type: str
    amount: float

class ResourceCreate(ResourceBase):
    pass

class Resource(ResourceBase):
    id: int
    user_id: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class GameStateBase(BaseModel):
    current_planet: str
    current_level: int
    score: float

class GameStateCreate(GameStateBase):
    pass

class GameState(GameStateBase):
    id: int
    user_id: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class CosmeticBase(BaseModel):
    cosmetic_type: str
    cosmetic_id: str
    is_equipped: bool = False

class CosmeticCreate(CosmeticBase):
    pass

class Cosmetic(CosmeticBase):
    id: int
    user_id: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class ShopItemBase(BaseModel):
    item_type: str
    item_id: str
    price: float
    is_available: bool = True

class ShopItemCreate(ShopItemBase):
    pass

class ShopItem(ShopItemBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class ECNBase(BaseModel):
    ecn_type: str
    ecn_id: str
    is_active: bool = True

class ECNCreate(ECNBase):
    pass

class ECN(ECNBase):
    id: int
    user_id: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True 