# Development Setup Guide

## Quick Start

### What You Need
- Godot Engine 4.4
- Python 3.8+
- SQLite (included with Python)
- Git (optional)
- A code editor (VS Code recommended)

### Setting Up the Game
1. Download and install Godot 4.4
2. Clone or download the repository
3. Open the project in Godot

### Setting Up the Server
1. Install Python dependencies:
   ```bash
   pip install -r Database/requirements.txt
   ```
2. Initialize the database:
   ```bash
   python Database/init_db.py
   ```
3. Run the server:
   ```bash
   python Database/run_server.py
   ```

## Project Structure

### Main Directories
- **Scenes/**: All game scenes and scripts
  - **Menus/**: UI screens (dashboard, shop, etc.)
  - **GameObjects/**: Game entities (rocket, planets)
  - **DataScenes/**: Data handling scripts
  - **MapStuff/**: Map generation
- **Assets/**: Game assets
- **Textures/**: Texture files
- **Shaders/**: Custom shaders
- **Configs/**: Configuration files
- **Database/**: SQLite database and REST API server

### Key Files
- **project.godot**: Main project configuration
- **export_presets.cfg**: Export settings
- **Scenes/DataScenes/data_handler.gd**: Data management
- **Database/run_server.py**: REST API server
- **Database/models.py**: Database models
- **Database/schemas.py**: API schemas

## Development Workflow

### Making Changes
1. Open the project in Godot
2. Make your changes
3. Test in the editor
4. Export and test the build, test in both editor and exported builds

### Common Issues
- **Data not saving**: Check SQLite database permissions, if server and game are communicating, and whether local file permissions are set
- **Server connection issues**: Check if server is running

## Building the Game

### Export Settings
1. Go to Project > Export
2. Select your target platform
3. Configure export settings
4. Build the game

### Server Deployment
1. Make sure SQLite database is initialized
2. Start the server
3. Configure firewall if needed (hopefully not)
4. Server should work, monitor as needed

## Other things

### Performance
- Use object pooling
- Minimize physics calculations
- Optimize assets

# Setup Documentation

## Prerequisites

### Required Software
1. Python 3.8 or higher
2. SQLite (included with Python)
3. Godot Engine 4.0 or higher

### Python Dependencies
Install the required Python packages for the server:
```bash
pip install -r requirements.txt
```

The requirements include:
- FastAPI (0.109.2) - Web framework
- Uvicorn (0.27.1) - ASGI server
- SQLAlchemy (2.0.27) - Database ORM
- aiosqlite (0.19.0) - Async SQLite support
- Pydantic (2.6.1) - Data validation
- python-dotenv (1.0.1) - Environment variable management

## Server Setup

### Database Initialization
1. Navigate to the Database directory:
```bash
cd Database
```

2. Initialize the database:
```bash
python init_db.py
```

### Starting the Server
1. Start the server:
```bash
python run_server.py
```

The server will:
- Start on `http://localhost:8000`
- Create SQLite database file: `ecn_game.db`
- Use API version: v1
- Enable CORS for all origins

2. Verify the server is running:
- Visit `http://localhost:8000` - Should show "Server is running" message
- Visit `http://localhost:8000/docs` - Interactive API documentation (DNE atm)

## Game Setup

### Godot Project Setup
1. Open the project in Godot Engine
2. Ensure all required assets are in place:
   - Textures in `res://Textures/`
   - Scenes in `res://Scenes/`
   - Configs in `res://Configs/`

### Data Handler Setup
The game uses a DataHandler singleton for managing:
- User profiles
- Game state
- Resources (gas, scrap)
- Cosmetics
- Shop items
- ECNs
- Relationships
- Points allocation

### Profile Creation
1. Launch the game
2. If you are not logged in, clicking on the dashboard will prompt you to create a profile
   - Enter a profile name
   - Enter a user ID
   - Click "Create Profile"
3. The profile will be:
   - Stored locally
   - Synced with the server
   - Used for game progression

## API Integration

### Endpoints Used
The game communicates with the server using these endpoints:
- User Management: `/api/v1/users/`
- Resource Management: `/api/v1/resources/`
- Game State: `/api/v1/users/{user_id}/game_state`
- Cosmetics: `/api/v1/users/{user_id}/cosmetics`
- Shop: `/api/v1/shop/`
- Leaderboard: `/api/v1/leaderboard/`
- ECNs: `/api/v1/users/{user_id}/ecns`

### Data Synchronization
- Local data is stored in JSON files
- Server data is stored in SQLite database
- Automatic sync on profile creation/selection
- Manual sync available in dashboard

## Troubleshooting

### Common Issues
1. Server Connection Issues
   - Check if server is running
   - Verify server URL in DataHandler
   - Check network connectivity

2. Database Issues
   - Ensure database is initialized
   - Check file permissions
   - Verify database schema

3. Profile Issues
   - Check local storage permissions
   - Verify profile data format
   - Ensure server sync completed, and wait if need be - verify in log (common occurence)

### Debug Tools
1. Server Logs
   - Check console output
   - Monitor HTTP requests
   - Track database operations

2. Game Logs
   - Enable debug mode
   - Check DataHandler logs
   - Monitor network requests

## Future Improvements

### Server Enhancements
- Add authentication
- Implement rate limiting
- Add data validation
- Improve error handling (although it feels alright for me for now, still not perfect)

### Game Enhancements
- Add offline mode
- Improve data caching
- Add data backup
- Enhance error recovery

### Deployment Considerations
- Use production-grade database
- Implement proper security
- Set up monitoring
- Configure backups