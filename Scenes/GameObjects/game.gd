extends Node2D

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
	var materials = DataHandler.get_user_materials(user_id)
	
	print("DEBUG: Before update - Current resources:", materials)
	
	# Add 1000 to each resource
	var new_gas = materials.get("gas", 0) + 1000
	var new_scrap = materials.get("scrap", 0) + 1000
	
	print("DEBUG: Planning to update to - Gas:", new_gas, ", Scrap:", new_scrap)
	
	# Store updated resources
	DataHandler.store_materials(user_id, new_gas, new_scrap)
	
	# Wait a moment and check if values were stored correctly
	await get_tree().create_timer(0.5).timeout
	
	# Check retrieved data after update
	var updated_materials = DataHandler.get_user_materials(user_id)
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
	var materials = DataHandler.get_user_materials(user_id)
	
	print("Loading resources for user: ", user_id)
	print("Materials data: ", materials)
	
	# Ensure the labels exist and update them
	if gas_label and scrap_label:
		gas_label.text = str(materials.get("gas", 0))
		scrap_label.text = str(materials.get("scrap", 0))
		print("Set resource labels - Gas: ", gas_label.text, ", Scrap: ", scrap_label.text)

func _ready() -> void:
	# Initialize player data if needed
	DataHandler.initialize_player_data(DataHandler.get_user_id())
	
	# Update resource display
	update_resource_display()
	
	# First set up all planets
	generate_planets_from_config()
	for planet in get_tree().get_nodes_in_group("planets"):
		planet.traverse_requested.connect(_on_planet_traverse_requested)

	# Get camera reference
	var camera = $Camera
	# Set camera for all planets
	for planet in get_tree().get_nodes_in_group("Planets"):
		planet.set_camera(camera)
	
	# Load rockets with slight delay to ensure planets are ready
	call_deferred("load_rockets")



#################################################################### ROCKETS ##################################################################################

func load_rockets():
	load_current_user_rocket()
	load_peer_rockets()

func load_current_user_rocket():
	var user_id = DataHandler.get_user_id()
	var rocket_data = DataHandler.get_rocket_data(user_id)
	spawn_rocket(user_id, rocket_data.get("planet_id", "Planet_1"))


func load_peer_rockets():
	var user_id = DataHandler.get_user_id()
	var user_planet = DataHandler.get_rocket_data(user_id).get("planet_id", "Planet_1")
	
	# Get other rockets on the same planet
	var planet_rockets = DataHandler.get_rockets_on_planet(user_planet)
	
	# Remove current user from the list
	planet_rockets.erase(user_id)
	
	# Randomly select up to MAX_ROCKET_PLANET peers
	planet_rockets.shuffle()
	for i in range(min(planet_rockets.size(), MAX_ROCKET_PLANET)):
		spawn_rocket(planet_rockets[i], user_planet)

func spawn_rocket(rocket_id: String, planet_id: String):
	# Don't spawn if already exists
	if has_node(rocket_id):
		return

	#Create the rocket obj	
	var rocket_instance = RocketScene.instantiate()
	rocket_instance.name = rocket_id
	add_child(rocket_instance)

	var planet_node = get_node_or_null(planet_id)
	if planet_node:
		add_rocket_to_planet(rocket_id, planet_id)

func add_rocket_to_planet(rocket_id: String, planet_name: String):
	var rocket_node = get_node_or_null(rocket_id)
	var target_planet = get_node_or_null(planet_name)
	
	if target_planet and rocket_node:
		rocket_node.set_parent_planet(target_planet)


#################################################################### PLANETS ##################################################################################


func generate_planets_from_config():
	var planet_configs = load("res://Configs/planet_config.gd").PLANET_CONFIGS
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF

	for planet in planet_configs:
		var planet_data = {
			"id": planet.get("id", "Unknown_Planet"),
			"name": planet.get("name", planet.get("id", "Unknown_Planet")),
			"position": Vector2(planet.get("posX", 0), planet.get("posY", 0)),
			"scale": Vector2(planet.get("scale", 1.0), planet.get("scale", 1.0)),
			"texture": planet.get("texture", "planet"),
			"resource_cost": planet.get("resource_cost", {"gas": 0, "scrap": 0})
		}
	
		add_planet_to_map(planet_data)
		
		# Update bounds
		min_x = min(min_x, planet_data.position.x)
		max_x = max(max_x, planet_data.position.x)
		min_y = min(min_y, planet_data.position.y)
		max_y = max(max_y, planet_data.position.y)
	
	# Center camera on planets
	center_camera_on_planets(min_x, max_x, min_y, max_y)

func center_camera_on_planets(min_x: float, max_x: float, min_y: float, max_y: float):
	var camera = get_node_or_null("Camera")
	if not camera:
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
	var user_materials = DataHandler.get_user_materials(user_id)
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
	var materials = DataHandler.get_user_materials(user_id)
	
	# Deduct resources
	var new_gas = materials.get("gas", 0) - target_planet.planet_data.resource_cost.gas
	var new_scrap = materials.get("scrap", 0) - target_planet.planet_data.resource_cost.scrap
	
	# Update materials in DataHandler
	DataHandler.store_materials(user_id, new_gas, new_scrap)
	
	# Update the UI to reflect new resource values
	update_resource_display()
	
	# Update rocket position in DataHandler
	DataHandler.store_rocket_position(user_id, target_planet.name)
	
	# Remove rocket from current planet's orbit
	var current_planet = get_node_or_null(DataHandler.get_rocket_position(user_id))
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
	var planet_rockets = DataHandler.get_rockets_on_planet(planet_id)
	var user_id = DataHandler.get_user_id()
	
	# Remove current user from the list
	planet_rockets.erase(user_id)
	
	# Randomly select up to MAX_ROCKET_PLANET peers
	planet_rockets.shuffle()
	for i in range(min(planet_rockets.size(), MAX_ROCKET_PLANET)):
		spawn_rocket(planet_rockets[i], planet_id)
