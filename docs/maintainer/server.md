# Server Documentation

## Quick Start

### Prerequisites
1. Python 3.8 or higher
2. SQLite (included with Python)

### Installing Required Software

#### Python Dependencies
Install the required Python packages:
```bash
pip install -r requirements.txt
```

### Running the Server

1. First, initialize the database:
```bash
python init_db.py
```

2. Then start the server:
```bash
python run_server.py
```

The server will:
- Start on `http://localhost:8000`
- Create SQLite database file: `ecn_game.db`
- Use API version: v1
- Enable CORS for all origins

You can verify the server is running by visiting:
- `http://localhost:8000` - Should show "Server is running" message
- `http://localhost:8000/docs` - Interactive API documentation (DNE atm)

## How It Works

### Server Architecture
The server is built using FastAPI and provides a REST API for game data management:

1. **REST API Endpoints**
   - Handles persistent data storage and data communication via REST API calls
   - Uses SQLAlchemy in Python for database operations
   - Utillizes async/await for better performance, be aware of delays in current system

2. **SQLite Database**
   - Stores all persistent game data
   - Uses SQLAlchemy ORM for data modeling
   - Supports async operations through aiosqlite

### Key Components

#### Data Models
- `User`: User profiles and settings
- `GameState`: Game state information
- `Resource`: User materials (gas, scrap)
- `Cosmetic`: Rocket customization data
- `ShopItem`: Available items for purchase
- `ECN`: ECN submission records
- `Relationship`: User relationships
- `PointsAllocation`: Points allocation records

#### Database Tables
- `users`: User profiles and data
- `game_states`: Game state information
- `resources`: User materials and resources
- `cosmetics`: Rocket customization data
- `shop_items`: Available items for purchase
- `ecns`: ECN submission records
- `relationships`: User relationships
- `points_allocations`: Points allocation records

## API Endpoints

### User Management
- `POST /api/v1/users/`: Create new user
- `GET /api/v1/users/{user_id}`: Get user data
- `PUT /api/v1/users/{user_id}`: Update user data

### Resource Management
- `GET /api/v1/resources/{user_id}`: Get user materials (gas, scrap)
- `PUT /api/v1/resources/{user_id}`: Update user materials
  ```json
  {
    "gas": 100,
    "scrap": 50
  }
  ```

### Game State Management
- `GET /api/v1/users/{user_id}/game_state`: Get user's game state
- `POST /api/v1/users/{user_id}/game_state`: Update user's game state
  ```json
  {
    "current_planet": "Planet_1",
    "current_level": 1,
    "score": 0
  }
  ```

### Cosmetic Management
- `GET /api/v1/users/{user_id}/cosmetics`: Get user's rocket cosmetics
- `PUT /api/v1/users/{user_id}/cosmetics`: Update user's rocket cosmetics

### Shop Management
- `GET /api/v1/shop/items`: Get all available shop items
- `POST /api/v1/shop/purchase`: Purchase an item
  ```json
  {
    "user_id": "user123",
    "item_id": "cosmetic789"
  }
  ```

### Leaderboard Management
- `GET /api/v1/leaderboard/global`: Get global leaderboard
- `GET /api/v1/leaderboard/planet/{planet_id}`: Get planet-specific leaderboard

### ECN Management
- `GET /api/v1/users/{user_id}/ecns`: Get user's ECN submissions
- `POST /api/v1/ecns/submit`: Submit a new ECN
  ```json
  {
    "user_id": "user123",
    "ecn_id": "ecn456"
  }
  ```

### Data Import/Export
- `POST /api/v1/import/users`: Import users from CSV
- `POST /api/v1/import/game_states`: Import game states from CSV
- `GET /api/v1/export/users`: Export all user data

## Example API Usage

### Creating a New User
```json
{
    "id": "user123",
    "username": "player1",
    "email": "player1@example.com"
}
```

### Updating Game State
```json
{
    "current_planet": "Planet_2",
    "current_level": 2,
    "score": 1000
}
```

## Extending the Server

### Adding New Features
1. Add a new model in `models.py`
2. Create a new router in the `routers` directory
3. Add the router to `server.py`
4. Update the API documentation

### Example: Adding a New Endpoint
```python
@router.post("/new-feature/")
async def new_feature(data: NewFeatureData, db: AsyncSession = Depends(get_db)):
    # Handle the new feature
    result = await process_new_feature(data, db)
    return {"result": result}
```

## Future Potential Deployment Ideas

### Running in Production
- Use a process manager like PM2 or Supervisor
- Set up proper logging
- Configure firewall rules, discuss as needed with IT
- Implement proper login and other authentication
- Set up SSL/TLS for secure connections

### Scaling Considerations
- The server is designed for small to medium player counts currently
- In the case that the scale grows larger, consider:
  - Migrating to PostgreSQL or another production-grade database
  - Implementing caching
  - Using a load balancer
  - Setting up database replication