extends Area2D

# Visual feedback values
var original_scale = scale
var original_modulate = modulate

# UI Components
@onready var leaderboard = $Leaderboard
@onready var closeButton = $Leaderboard/MarginContainer/VBoxContainer/CloseButton
@onready var leaderboardList = $Leaderboard/MarginContainer/VBoxContainer/LeaderboardList
@onready var planet_label = $PlanetLabel

# Planet data storage
var planet_data = {}
"""
Planet data structure:
id: String, the id of the planet
name: String, the display name of the planet
position: Vector2, position of planet
scale: Vector2, size of planet
step: int, the step along the path on the main game
"""

# Orbit Parameters
const BASE_ORBIT_RADIUS = 35
const RADIUS_INCREMENT = 25
const MAX_ROCKETS_PER_ORBIT = 6
var rocket_orbits = {}


# Camera reference for UI
var camera = null


#################################################################### HOUSEKEEPING FUNCS ##################################################################################

func configure(data: Dictionary):
	planet_data = data
	
	# Set position and scale
	position = data.get("position", Vector2.ZERO)
	scale = data.get("scale", Vector2.ONE)
	
	# Load texture if specified
	if data.has("texture"):
		var texture_path = "res://Textures/%s.png" % data.texture
		if ResourceLoader.exists(texture_path):
			$PlanetSprite.texture = load(texture_path)


func _ready() -> void:
	# Initialize UI state
	leaderboard.visible = false
	closeButton.pressed.connect(close_menu)
	
	# Store initial values for hover effects
	original_scale = scale
	original_modulate = modulate

	if not camera:
		camera = get_node("/root/Game/Camera") 

	# Set planet name label
	if planet_label and planet_data:
		var planet_name = planet_data.get("name", planet_data.get("id", "Unknown Planet"))
		print("Setting planet name to: ", planet_name)  # Debug print
		planet_label.text = planet_name
		center_planet_label()
	else:
		print("Warning: PlanetLabel node not found or planet_data not set!")  # Debug print

	#on planet enterring the scene, load its ships, especially the given player's for now
	
#################################################################### SIGNALS ##################################################################################

signal traverse_requested(planet_id)

# Hover feedback
func _on_mouse_entered() -> void:
	scale = scale * 1.05
	modulate = Color(1, 1, 0.85, 1)

func _on_mouse_exited() -> void:
	scale = original_scale
	modulate = Color(1, 1, 1, 1)

# Click handling
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		var user_id = DataHandler.get_user_id()
		var user_planet = DataHandler.get_rocket_position(user_id)

		if name != user_planet:
			#signal to game node to handle traversal if the user is not at the the planet
			traverse_requested.emit(name)
		else:
			#open the leaderboard if user at that planet
			open_leaderboard()


#################################################################### CAMERA ##################################################################################


func set_camera(camera_ref):
	camera = camera_ref

func calculate_camera_view():
	if not camera:
		return
		
	# Get planet size (including orbit radius)
	var planet_radius = ($PlanetSprite.texture.get_width() * scale.x / 2) + (BASE_ORBIT_RADIUS * scale.x)
	
	# Get leaderboard size
	var leaderboard_size = leaderboard.get_rect().size * leaderboard.scale
	
	# Calculate total width needed to show both planet and leaderboard
	var total_width = planet_radius * 2 + leaderboard_size.x + 50  # 50 pixels padding
	var total_height = max(planet_radius * 2, leaderboard_size.y) + 50
	
	# Calculate required zoom to fit everything
	var viewport_size = get_viewport_rect().size
	var zoom_x = viewport_size.x / total_width
	var zoom_y = viewport_size.y / total_height
	var zoom_level = min(zoom_x, zoom_y)
	
	# Calculate center position between planet and leaderboard
	var leaderboard_offset = Vector2(planet_radius + leaderboard_size.x/2, 0)
	var center_position = global_position + leaderboard_offset/2
	
	# Apply camera transform
	camera.lock_to_position(center_position, Vector2(zoom_level, zoom_level))


#################################################################### LEADERBOARD ##################################################################################


# Menu handling
func open_leaderboard():
	leaderboard.visible = true
	load_leaderboard()

	# Position camera to show leaderboard
	if camera:
		print("camera found")

		var leaderboard_offset = Vector2(250, 0)
		var camera_target = global_position + leaderboard_offset / 2
		var zoom_level = Vector2(2.5, 2.5)
		camera.lock_to_position(camera_target, zoom_level)
	else:
		print("camera not found")

func close_menu():
	leaderboard.visible = false
	if camera:
		camera.unlock_camera()

# Leaderboard functionality
func load_leaderboard():
	leaderboardList.clear()
	
	var leaderboard_data = DataHandler.get_planet_leaderboard(planet_data.get("id", "Unknown"), 10)
	
	for entry in leaderboard_data:
		leaderboardList.add_item(
			"%d. %s | Points: %d" % [
				entry["rank"],
				entry["name"],
				entry["points"]
			]
		)


#################################################################### ROCKET ##################################################################################

# Orbit management
func get_orbit_data_for_rocket(rocket_id: String) -> Dictionary:
	# Add rocket to tracking
	if not rocket_orbits.has(rocket_id):
		rocket_orbits[rocket_id] = true
	
	var total_rockets = rocket_orbits.size()
	
	# Determine which orbit this rocket should be in
	var orbit_level = (total_rockets - 1) / MAX_ROCKETS_PER_ORBIT
	
	# Calculate orbit radius based on planet scale and orbit level
	var orbit_radius = (BASE_ORBIT_RADIUS + (orbit_level * RADIUS_INCREMENT)) * scale.x
	
	# Calculate how many rockets are in the current orbit
	var rockets_in_current_orbit = min(total_rockets - (orbit_level * MAX_ROCKETS_PER_ORBIT), MAX_ROCKETS_PER_ORBIT)
	
	# Calculate even spacing between rockets in this orbit
	var angle_step = (2 * PI) / rockets_in_current_orbit
	
	# Calculate this rocket's position in the current orbit
	var position_in_orbit = (total_rockets - 1) % MAX_ROCKETS_PER_ORBIT
	
	# Calculate the angle (plus a small random offset for visual variety)
	var angle = angle_step * position_in_orbit
	
	# Add a small random offset to the radius for visual variety
	var radius_variation = randf_range(-5, 5) * scale.x
	
	return {
		"radius": orbit_radius + radius_variation,
		"angle": angle
	}

func remove_rocket_from_orbit(rocket_id: String):
	if rocket_orbits.has(rocket_id):
		rocket_orbits.erase(rocket_id)

func center_planet_label() -> void:
	if planet_label:
		# Fixed position below the planet
		planet_label.position = Vector2(0, 25)  # Fixed distance below planet
		
		# Fixed scale that works well with the current setup
		planet_label.scale = Vector2(0.2, 0.2)  # Smaller fixed scale
		
		# Ensure text is centered
		planet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
