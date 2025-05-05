# Contributing Guide

## Getting Started

### Setting Up Your Environment
- Install Godot 4.4
- Set up Python for the server
- Clone the repository
- Open the project in Godot

### Understanding the Codebase
- The game is built in Godot with GDScript
- The server is a simple Python WebSocket server
- Data is stored in JSON files
- Key files to understand:
  - `data_handler.gd`: Manages all game data
  - `middleware_server.py`: Handles multiplayer communication
  - `game.gd`: Main game logic
  - `rocket.gd`: Rocket controls and physics

## Making Changes

### Debugging Tips
- Check the log files in `user://data/game_log.txt`
- Godot's debugger is not the best, but it is usable - There aren't any alternatives so get used to it
- Test in both editor and exported builds, the behavior can change fairly notably between the two

### Common Issues
- **Data not saving**: Check file permissions
- **Server connection issues**: Verify port in use is open
- **UI glitches**: Test on different resolutions

### Game Testing
- Verify on different platforms when possible, sometimes build is funky on ASML hardware
- Test and verify with different data sets when possible

### Server Testing
- Run the server locally
- Test with multiple clients
- Check error handling

## Deployment

### Building the Game
1. Use Godot's export feature
2. Select the appropriate platform
3. Configure export settings
4. Build and test the exported version

### Updating the Server
1. Stop the current server
2. Deploy the new version
3. Restart the server
4. Monitor for any issues

## Tips and Tricks

### Godot-Specific Tips
- Learn the signal and scene system in Godot
- Godot is open source and open to change, you can alter the engine if that helps fix anything (probably don't do that, though)

### Data Management Tips
- **!! Always validate data before saving !!**
- This is not the most secure internet protocol, so if any secure information may be being transferred in the future, make sure to use encryption.
- Always transfer bare minimum amount of info to the users regarding other user info (avoid redundancy, avoid sharing private info such as helpfulness points given, etc.)
- Use only data handler's built-in functions to handle data
- Back up data before major changes