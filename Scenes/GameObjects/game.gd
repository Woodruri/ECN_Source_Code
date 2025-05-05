extends Node2D

const PlanetConfig = preload("res://Configs/planet_config.gd")

var PlanetScene = preload("res://Scenes/GameObjects/blank_planet.tscn")
var RocketScene = preload("res://Scenes/GameObjects/Rocket.tscn")

var MAX_ROCKET_PLANET = 5 #Max rockets to be loaded per planet

# Resource display references
@onready var gas_label = $UI/ResourceDisplay/HBoxContainer/GasContainer/GasLabel
@onready var scrap_label = $UI/ResourceDisplay/HBoxContainer/ScrapContainer/ScrapLabel

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn")

func _on_debug_button_pressed() -> void:
	# Get current resources
	var user_id = DataHandler.get_user_id()
	var materials = await DataHandler.get_user_materials(user_id)
	
	print("DEBUG: Before update - Current resources:", materials)
	
	# Add 1000 to each resource
	var new_gas = materials.get("gas", 0) + 1000
	var new_scrap = materials.get("scrap", 0) + 1000
	
	print("DEBUG: Planning to update to - Gas:", new_gas, ", Scrap:", new_scrap)
	
	# Store updated resources
	await DataHandler.store_materials(user_id, new_gas, new_scrap)
	
	# Wait a moment and check if values were stored correctly
	await get_tree().create_timer(0.5).timeout
	
	# Check retrieved data after update
	var updated_materials = await DataHandler.get_user_materials(user_id)
	print("DEBUG: After update - Retrieved resources:", updated_materials)
	
	# Force direct update of UI
	if gas_label and scrap_label:
		gas_label.text = str(new_gas)
		scrap_label.text = str(new_scrap)
		print("DEBUG: Directly updated UI labels - Gas:", gas_label.text, ", Scrap:", scrap_label.text)
	
	# Call update_resource_display again to ensure UI is refreshed
	update_resource_display()
	
	print("DEBUG: Added 1000 gas and 1000 scrap")

func update_resource_display() -> void:
	var user_id = DataHandler.get_user_id()
	var materials = await DataHandler.get_user_materials(user_id)
	
	print("Loading resources for user: ", user_id)
	print("Materials data: ", materials)
	
	# Ensure the labels exist and update them
	if gas_label and scrap_label:
		gas_label.text = str(materials.get("gas", 0))
		scrap_label.text = str(materials.get("scrap", 0))
		print("Set resource labels - Gas: ", gas_label.text, ", Scrap: ", scrap_label.text)

func _ready() -> void:
	print("Initializing game...")
	
	# Check if PlanetConfig is loaded
	if not PlanetConfig:
		print("Error: PlanetConfig not loaded!")
		return
		
	print("PlanetConfig loaded successfully")
	print("Number of planet configs: ", PlanetConfig.PLANET_CONFIGS.size())
	
	# Initialize player data if needed
	var user_id = DataHandler.get_user_id()
	if user_id.is_empty():
		print("Error: No user ID set!")
		return
		
	print("Initializing player data for user: ", user_id)
	await DataHandler.initialize_player_data(user_id)
	print("Player data initialized")
	
	# Update resource display
	update_resource_display()
	print("Resource display updated")
	
	# Initialize game state
	print("Loading game state...")
	var game_state = await DataHandler.get_rocket_data(user_id)
	print("Game state loaded: ", game_state)
	
	# First set up all planets
	print("Starting planet generation...")
	generate_planets_from_config()
	
	# Get camera reference
	var camera = $Camera
	if not camera:
		print("Error: Camera node not found")
		return
	print("Camera found")
	
	# Set camera for all planets and connect signals
	var planets = get_tree().get_nodes_in_group("planets")
	print("Found ", planets.size(), " planets in scene")
	
	for planet in planets:
		if planet:
			planet.set_camera(camera)
			planet.traverse_requested.connect(_on_planet_traverse_requested)
			print("Connected planet: ", planet.name)
		else:
			print("Warning: Null planet found in group")
	
	# Calculate bounds for camera centering
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for planet in planets:
		if planet:
			var pos = planet.position
			min_x = min(min_x, pos.x)
			max_x = max(max_x, pos.x)
			min_y = min(min_y, pos.y)
			max_y = max(max_y, pos.y)
	
	print("Camera bounds calculated: ", Vector2(min_x, min_y), " to ", Vector2(max_x, max_y))
	
	# Center camera on planets
	center_camera_on_planets(min_x, max_x, min_y, max_y)
	print("Camera centered")
	
	# Load rockets with slight delay to ensure planets are ready
	await get_tree().create_timer(0.5).timeout
	load_rockets()
	print("Rockets loaded")
	
	print("Game initialization complete")

#################################################################### ROCKETS ##################################################################################

func load_rockets():
	print("Loading rockets...")
	load_current_user_rocket()
	load_peer_rockets()

func load_current_user_rocket():
	print("Loading current user rocket...")
	var user_id = DataHandler.get_user_id()
	var rocket_data = await DataHandler.get_rocket_data(user_id)
	print("Rocket data loaded: ", rocket_data)
	spawn_rocket(user_id, rocket_data.get("planet_id", "Planet_1"))

func load_peer_rockets():
	print("Loading peer rockets...")
	var user_id = DataHandler.get_user_id()
	var rocket_data = await DataHandler.get_rocket_data(user_id)
	var user_planet = rocket_data.get("planet_id", "Planet_1")
	
	# Get other rockets on the same planet
	var rockets_on_planet = await DataHandler.get_rockets_on_planet(user_planet)
	print("Rockets on planet: ", rockets_on_planet)
	
	# Remove current user from the list
	rockets_on_planet.erase(user_id)
	
	# Randomly select up to MAX_ROCKET_PLANET peers
	rockets_on_planet.shuffle()
	for i in range(min(rockets_on_planet.size(), MAX_ROCKET_PLANET)):
		spawn_rocket(rockets_on_planet[i], user_planet)

func spawn_rocket(rocket_id: String, planet_id: String):
	print("Spawning rocket: ", rocket_id, " on planet: ", planet_id)
	
	# Don't spawn if already exists
	if has_node(rocket_id):
		print("Rocket already exists: ", rocket_id)
		return

	#Create the rocket obj	
	var rocket_instance = RocketScene.instantiate()
	rocket_instance.name = rocket_id
	add_child(rocket_instance)
	
	# Ensure cosmetics are loaded for this rocket
	rocket_instance.load_cosmetics()

	var planet_node = get_node_or_null(planet_id)
	if planet_node:
		add_rocket_to_planet(rocket_id, planet_id)
	else:
		print("Error: Planet not found: ", planet_id)

func add_rocket_to_planet(rocket_id: String, planet_name: String):
	var rocket_node = get_node_or_null(rocket_id)
	var target_planet = get_node_or_null(planet_name)
	
	if target_planet and rocket_node:
		rocket_node.set_parent_planet(target_planet)

#################################################################### PLANETS ##################################################################################

func generate_planets_from_config() -> void:
	print("Starting planet generation...")
	var planet_scene = preload("res://Scenes/GameObjects/blank_planet.tscn")
	
	if not planet_scene:
		print("Error: Could not load planet scene")
		return
		
	print("Planet configs to generate: ", PlanetConfig.PLANET_CONFIGS.size())
	
	for config in PlanetConfig.PLANET_CONFIGS:
		print("Generating planet: ", config.name)
		var planet = planet_scene.instantiate()
		if not planet:
			print("Error: Failed to instantiate planet for ", config.name)
			continue
			
		planet.planet_id = config.id
		planet.planet_name = config.name
		planet.position = Vector2(config.posX, config.posY)
		planet.scale = Vector2(config.scale, config.scale)
		planet.resource_cost = config.resource_cost
		
		# Set planet texture
		var texture_path = "res://Textures/" + config.texture + ".png"
		var texture = load(texture_path)
		if texture:
			var sprite = planet.get_node("Sprite2D")
			if sprite:
				sprite.texture = texture
				sprite.visible = true  # Ensure sprite is visible
			else:
				print("Error: No Sprite2D node found in planet for ", config.name)
		else:
			print("Warning: Could not load texture for planet: ", config.texture)
		
		# Add to scene and group
		add_child(planet)
		planet.add_to_group("planets")
		
		# Verify planet position and visibility
		print("Planet ", config.name, " details:")
		print("- Position: ", planet.position)
		print("- Scale: ", planet.scale)
		print("- Visible: ", planet.visible)
		if planet.get_node("Sprite2D"):
			print("- Sprite visible: ", planet.get_node("Sprite2D").visible)
			print("- Sprite texture: ", planet.get_node("Sprite2D").texture != null)
	
	print("Planet generation complete. Total planets: ", get_tree().get_nodes_in_group("planets").size())
	
	# Verify all planets are in the scene tree
	for planet in get_tree().get_nodes_in_group("planets"):
		print("Verifying planet in scene: ", planet.name)
		print("- Is in scene tree: ", planet.is_inside_tree())
		print("- Global position: ", planet.global_position)
		print("- Parent: ", planet.get_parent().name if planet.get_parent() else "No parent")

func center_camera_on_planets(min_x: float, max_x: float, min_y: float, max_y: float):
	var camera = get_node_or_null("Camera")
	if not camera:
		print("Error: Camera not found for centering")
		return
		
	# Calculate center point
	var center_x = (min_x + max_x) / 2
	var center_y = (min_y + max_y) / 2
	
	# Add some padding to the bounds
	var padding = 200  # Adjust this value to change how much padding there is around the planets
	min_x -= padding
	max_x += padding
	min_y -= padding
	max_y += padding
	
	# Calculate the zoom level needed to fit all planets
	var viewport_size = get_viewport_rect().size
	var world_size = Vector2(max_x - min_x, max_y - min_y)
	var zoom_x = viewport_size.x / world_size.x
	var zoom_y = viewport_size.y / world_size.y
	var zoom = min(zoom_x, zoom_y) * 0.8  # 0.8 to add some margin
	
	# Set camera position and zoom
	camera.position = Vector2(center_x, center_y)
	camera.zoom = Vector2(zoom, zoom)
	
	print("Camera centered:")
	print("- Position: ", camera.position)
	print("- Zoom: ", camera.zoom)
	print("- Viewport size: ", viewport_size)
	print("- World bounds: ", Vector2(min_x, min_y), " to ", Vector2(max_x, max_y))

func add_planet_to_map(planet_data: Dictionary):
	#takes a planet dicitonary object and then adds it to the game world
	# Used to dynamically load the world without needing to do it all manually
	var planet_instance = PlanetScene.instantiate()
	
	# Configure planet
	planet_instance.name = planet_data.id
	planet_instance.configure(planet_data)
	
	# Add to planet group for easy reference
	planet_instance.add_to_group("planets")
	
	# Add to scene
	add_child(planet_instance)

#################################################################### TRAVERSAL ##################################################################################

func _on_planet_traverse_requested(planet_id: String):
	#in response to the planet_traverse signal in blank_planet.gd

	var user_id = DataHandler.get_user_id()
	var user_materials = await DataHandler.get_user_materials(user_id)
	var target_planet = get_node_or_null(planet_id)
	
	if not target_planet:
		print("No target planet found")
		return
		
	# Check resources
	if has_enough_resources(user_materials, target_planet.planet_data.resource_cost):
		show_traverse_confirmation(target_planet)
	else:
		show_insufficient_resources_dialog(target_planet.planet_data.resource_cost)

func has_enough_resources(materials: Dictionary, cost: Dictionary) -> bool:
	return materials.get("gas", 0) >= cost.gas and materials.get("scrap", 0) >= cost.scrap

func show_traverse_confirmation(target_planet: Node):
	# Use ConfirmationDialog instead of AcceptDialog for better button control
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Would you like to travel to %s?\nCost: %d Gas, %d Scrap" % [
		target_planet.name,
		target_planet.planet_data.resource_cost.gas,
		target_planet.planet_data.resource_cost.scrap
	]
	
	# Customize the default buttons
	dialog.ok_button_text = "Travel"
	dialog.cancel_button_text = "Cancel"
	
	# Connect to handle responses
	dialog.confirmed.connect(func(): traverse_to_planet(target_planet))
	
	# Connect to cleanup when dialog closes
	dialog.canceled.connect(func():
		var camera = get_node_or_null("Camera")
		if camera:
			camera.is_dragging = false
	)
	
	dialog.close_requested.connect(func():
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()
	
	# Set size to make sure text fits nicely
	dialog.min_size = Vector2(300, 150)

func show_insufficient_resources_dialog(cost: Dictionary):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Not enough resources to travel!\nRequired: %d Gas, %d Scrap" % [
		cost.gas,
		cost.scrap
	]
	
	# Set the button text to just "OK"
	dialog.ok_button_text = "OK"
	
	# Connect to cleanup when dialog closes
	dialog.close_requested.connect(func(): 
		var camera = get_node_or_null("Camera")
		if camera:
			camera.is_dragging = false
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()
	dialog.min_size = Vector2(300, 100)

func traverse_to_planet(target_planet: Node):
	var user_id = DataHandler.get_user_id()
	var materials = await DataHandler.get_user_materials(user_id)
	
	# Deduct resources
	var new_gas = materials.get("gas", 0) - target_planet.planet_data.resource_cost.gas
	var new_scrap = materials.get("scrap", 0) - target_planet.planet_data.resource_cost.scrap
	
	# Update materials in DataHandler
	await DataHandler.store_materials(user_id, new_gas, new_scrap)
	
	# Update the UI to reflect new resource values
	update_resource_display()
	
	# Update rocket position in DataHandler
	await DataHandler.store_rocket_position(user_id, target_planet.name)
	
	# Remove rocket from current planet's orbit
	var current_rocket_data = await DataHandler.get_rocket_data(user_id)
	var current_planet = get_node_or_null(current_rocket_data.get("planet_id", ""))
	if current_planet:
		var rocket = get_node_or_null(user_id)
		if rocket:
			rocket.set_parent_planet(null)  # Detach from current planet
	
	# Move rocket to new planet
	add_rocket_to_planet(user_id, target_planet.name)
	
	# Refresh peer rockets on both planets
	if current_planet:
		load_peer_rockets_for_planet(current_planet.name)
	load_peer_rockets_for_planet(target_planet.name)

func load_peer_rockets_for_planet(planet_id: String):
	# Clear existing peer rockets on this planet
	var existing_rockets = get_tree().get_nodes_in_group("rockets")
	for rocket in existing_rockets:
		if rocket.name != DataHandler.get_user_id():  # Don't remove player's rocket
			rocket.queue_free()
	
	# Get other rockets on the planet
	var rockets_on_planet = await DataHandler.get_rockets_on_planet(planet_id)
	var user_id = DataHandler.get_user_id()
	
	# Remove current user from the list
	rockets_on_planet.erase(user_id)
	
	# Randomly select up to MAX_ROCKET_PLANET peers
	rockets_on_planet.shuffle()
	for i in range(min(rockets_on_planet.size(), MAX_ROCKET_PLANET)):
		spawn_rocket(rockets_on_planet[i], planet_id)
