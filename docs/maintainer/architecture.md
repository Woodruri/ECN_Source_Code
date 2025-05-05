# Architecture Overview

## The Big Picture

### What This Game Is
ECN Game Space is a space exploration game where you:
- Fly a rocket through space, orbiting further and further planets as you progress
- Collect resources via ECN submissions
- Upgrade your rocket's cosmetics and compete (friendly competition only please) with other coworkers to have superior rocket cosmetics and whatnot
- Compete on leaderboards for top positions

### How It All Fits Together
```
[Game Client (Godot)] <-> [Data Handler (Godot, singleton)] <-> [REST API Server] <-> [MongoDB]
```

## Key Components

### Game Client (Godot)
- **Scenes/Menus**: All UI screens (dashboard, shop, etc.)
- **Scenes/GameObjects**: Game entities (rocket, planets, etc.)
- **Scenes/DataScenes**: Data handling scripts
- **Scenes/MapStuff**: Map generation and management

### Data Handler
- Manages all game data
- Handles saving and loading
- Tracks player progress
- Manages employee data
- Handles resource tracking
- Handles data caching
- Communicates with REST API server

### REST API Server
- FastAPI-based server
- Handles all data persistence
- Manages user profiles and game states
- Stores data in MongoDB

## Data Flow

### How Data Gets Saved
1. Player performs an action
2. Game updates internal state
3. Data handler sends update to REST API
4. REST API stores data in MongoDB
5. On screen change, game queries latest data from server

### How Multiplayer Works
1. Player actions are saved to server
2. Other players see updates when they change screens
3. Leaderboard and other shared data is queried on screen load

## File Structure

### Where Everything Lives
- **MongoDB Collections**:
  - `users`: User profiles and settings
  - `game_states`: Game state information
- **Scenes/**: All game scenes and scripts
- **Assets/**: Game assets (models, sounds)
- **Textures/**: Texture files
- **Shaders/**: Custom shaders (DNE currently)

## Game Systems

### Rocket System
- Simple orbit around planet
- Resource collection (possibly, DNE atm)
- Upgrade system (possibly, DNE atm)
- Customization options to express cosmetic creativity

### Planet System
- Generated from simple config, provided by admin (currently Dave)
- Resource distribution (possibly, DNE atm)
- Exploration mechanics (possibly, DNE atm)

### Shop and Customization System
- Customize Rocket through variety of parts and styles