# Development Setup Guide

## Quick Start

### What You Need
- Godot Engine 4.4
- Python 3.8+
- MongoDB Community Edition
- Git (optional)
- A code editor (VS Code recommended)

### Setting Up the Game
1. Download and install Godot 4.4
2. Clone or download the repository
3. Open the project in Godot

### Setting Up the Server
1. Install MongoDB Community Edition from [mongodb.com](https://www.mongodb.com/try/download/community)
2. Start MongoDB service:
   - Windows: MongoDB should run as a service
   - Linux: `sudo systemctl start mongod`
   - macOS: `brew services start mongodb`
3. Install Python dependencies:
   ```bash
   pip install -r server/requirements.txt
   ```
4. Run the server:
   ```bash
   python server/persistence_server.py
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
- **server/**: REST API server

### Key Files
- **project.godot**: Main project configuration
- **export_presets.cfg**: Export settings
- **Scenes/DataScenes/data_handler.gd**: Data management
- **Scenes/DataScenes/server_db_handler.gd**: Server communication
- **server/persistence_server.py**: REST API server

## Development Workflow

### Making Changes
1. Open the project in Godot
2. Make your changes
3. Test in the editor
4. Export and test the build, test in both editor and exported builds

### Common Issues
- **Data not saving**: Check MongoDB connection or file permissions
- **Server connection issues**: Check if server is running

## Building the Game

### Export Settings
1. Go to Project > Export
2. Select your target platform
3. Configure export settings
4. Build the game

### Server Deployment
1. Make sure MongoDB is running
2. Start the REST API server
3. Configure firewall if needed
4. Test with multiple clients
5. Monitor for issues

## Other things

### Performance
- Use object pooling
- Minimize physics calculations
- Optimize assets