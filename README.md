# ECN Game Space

A Godot-based game project that implements a space-themed game with a custom middleware server for multiplayer functionality and data persistence.

## Project Architecture

### Directory Structure

```
ECN_Game_Space/
├── Addons/           # Third-party plugins and extensions
├── Assets/          # Game assets (models, sounds, etc.)
├── Configs/         # Configuration files
├── Database/        # Database-related files and scripts
├── Scenes/          # Game scenes and scripts
│   ├── DataScenes/  # Data handling and persistence
│   ├── GameObjects/ # Game object definitions
│   ├── MapStuff/    # Map-related assets and scripts
│   └── Menus/       # UI and menu scenes
├── Shaders/         # Custom shader files
├── Textures/        # Texture assets
└── server/          # Middleware server
    ├── middleware_server.py  # Main server implementation
    └── requirements.txt      # Python dependencies
```

### Core Components

1. **Data Management**
   - `DataHandler`: Autoloaded singleton for managing local game data
   - `ServerDbHandler`: Autoloaded singleton for server communication
   - Located in `Scenes/DataScenes/`

2. **Game Scenes**
   - Main menu and UI elements in `Scenes/Menus/`
   - Game objects and entities in `Scenes/GameObjects/`
   - Map and level components in `Scenes/MapStuff/`

3. **Middleware Server**
   - FastAPI-based REST server for data persistence
   - SQLite database for storage
   - Handles game state synchronization
   - Manages player data and resources
   - Located in `Database/`

4. **Configuration**
   - Project settings in `project.godot`
   - Export presets in `export_presets.cfg`

## Getting Started

### Game Requirements
- Godot Engine 4.4 or higher
- Python 3.8 or higher
- SQLite (included with Python)

### Python Dependencies
Install the required Python packages:
```bash
pip install -r (whatever)/requirements.txt
```
Each folder may have different requirements for different needs, to avoid bloat, I would advise using a venv

### Setup

## Setup

### Server Setup
1. Initialize the database:
```bash
python Database/init_db.py
```

2. Start the server:
```bash
python Database/run_server.py
```

1. Start the middleware server (see Setup section)
2. Open the project in Godot Engine
3. The main scene is set to `res://Scenes/Menus/Menu.tscn`
4. Press F5 or click the "Play" button to run the game

## Development

### Adding New Features

1. **New Game Objects**
   - Create new scenes in `Scenes/GameObjects/`
   - Attach appropriate scripts and components
   - Register with the data handler if persistence is needed

2. **UI Elements**
   - Add new menu scenes in `Scenes/Menus/`
   - Follow the existing UI patterns for consistency

3. **Data Management**
   - Use `DataHandler` for local data operations
   - Use `ServerDbHandler` for server communication
   - Add new data structures in `Scenes/DataScenes/`

### Server Communication

The server provides the following features:

1. **State Synchronization**
   - Players can update their game state
   - State changes are stored in SQLite database
   - Clients can request current state information


### Best Practices

1. **Scene Organization**
   - Keep scenes modular and reusable
   - Use scene inheritance where appropriate
   - Follow the established directory structure

2. **Data Handling**
   - Always use the provided handlers for data operations
   - Implement proper error handling
   - Cache data when it feels appropriate

3. **Performance**
   - Use object pooling for frequently spawned objects
   - Avoid too too many shaders and textures
   - Implement proper cleanup in `_exit_tree()` (if necessary, you can probably ignore this)
   - Be aware of async/await delays in the current system

4. **Server Communication**
   - Implement proper error handling for network operations
   - Use appropriate message formats
   - Handle connection loss gracefully
