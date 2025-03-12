extends Node2D

var PlanetScene = preload("res://Scenes/GameObjects/blank_planet.tscn")
var RocketScene = preload("res://Scenes/GameObjects/Rocket.tscn")


var MAX_ROCKET_PLANET = 5 #Max rockets to be loaded per planet

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn")


func _ready() -> void:
	# Initialize player data if needed
	DataHandler.initialize_player_data(DataHandler.get_user_id())
	
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
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Would you like to travel to %s?\nCost: %d Gas, %d Scrap" % [
		target_planet.name,
		target_planet.planet_data.resource_cost.gas,
		target_planet.planet_data.resource_cost.scrap
	]
	
	dialog.add_button("Cancel", true, "cancel")
	dialog.add_button("Travel", false, "travel")
	
	# Connect to handle response
	dialog.confirmed.connect(func(): traverse_to_planet(target_planet))
	
	# Connect to cleanup when dialog closes
	dialog.close_requested.connect(func(): 
		var camera = get_node_or_null("Camera")
		if camera:
			camera.is_dragging = false
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()

func show_insufficient_resources_dialog(cost: Dictionary):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Not enough resources to travel!\nRequired: %d Gas, %d Scrap" % [
		cost.gas,
		cost.scrap
	]
	
	# Connect to cleanup when dialog closes
	dialog.close_requested.connect(func(): 
		var camera = get_node_or_null("Camera")
		if camera:
			camera.is_dragging = false
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()

func traverse_to_planet(target_planet: Node):
	var user_id = DataHandler.get_user_id()
	var materials = DataHandler.get_user_materials(user_id)
	
	# Deduct resources
	var new_gas = materials.get("gas", 0) - target_planet.planet_data.resource_cost.gas
	var new_scrap = materials.get("scrap", 0) - target_planet.planet_data.resource_cost.scrap
	
	# Update materials in DataHandler
	DataHandler.store_materials(user_id, new_gas, new_scrap)
	
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
