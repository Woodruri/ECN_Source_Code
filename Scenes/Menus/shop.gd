extends Control

# Shop items by category
var paint_items = [
	{
		"id": "red_rocket",
		"name": "Red Rocket Paint",
		"description": "Red paint job for your rocket.",
		"cost": {"gas": 100, "scrap": 50},
		"preview_image": null
	},
	{
		"id": "blue_rocket",
		"name": "Blue Rocket Paint",
		"description": "Blue paint job for your rocket.",
		"cost": {"gas": 100, "scrap": 50},
		"preview_image": null
	},
	{
		"id": "gold_trim",
		"name": "Gold Trim Package",
		"description": "Flex that money with GOLD.",
		"cost": {"gas": 300, "scrap": 200},
		"preview_image": null
	}
]

var exhaust_items = [
	{
		"id": "blue_exhaust",
		"name": "Blue Exhaust",
		"description": "Blue exhaust particles for your rocket.",
		"cost": {"gas": 150, "scrap": 75},
		"preview_image": null
	},
	{
		"id": "green_exhaust",
		"name": "Green Exhaust",
		"description": "Green exhaust particles for your rocket.",
		"cost": {"gas": 150, "scrap": 75},
		"preview_image": null
	},
	{
		"id": "purple_exhaust",
		"name": "Purple Exhaust",
		"description": "Purple exhaust particles for your rocket.",
		"cost": {"gas": 200, "scrap": 100},
		"preview_image": null
	}
]

var wings_items = [
	{
		"id": "small_wings",
		"name": "Small Wings",
		"description": "Small decorative wings for your rocket.",
		"cost": {"gas": 200, "scrap": 150},
		"preview_image": null
	},
	{
		"id": "large_wings",
		"name": "Large Wings",
		"description": "Large decorative wings for your rocket.",
		"cost": {"gas": 300, "scrap": 250},
		"preview_image": null
	},
	{
		"id": "bat_wings",
		"name": "Bat Wings",
		"description": "Bat-like wings for your rocket.",
		"cost": {"gas": 400, "scrap": 300},
		"preview_image": null
	}
]

var drone_items = [
	{
		"id": "mining_drone",
		"name": "Mining Drone",
		"description": "Automatically collects 5 scrap every x time period.",
		"cost": {"gas": 500, "scrap": 200},
		"production": {"scrap": 5}
	},
	{
		"id": "gas_drone",
		"name": "Gas Collector Drone",
		"description": "Automatically collects 5 gas every x time period.",
		"cost": {"gas": 200, "scrap": 500},
		"production": {"gas": 5}
	},
	{
		"id": "explorer_drone",
		"name": "Explorer Drone",
		"description": "I'm not rly sure what I want this drone to do but it sounds fun.",
		"cost": {"gas": 800, "scrap": 800},
		"production": {"gas": 2, "scrap": 2}
	}
]

# UI References
@onready var paint_list = $MainContainer/ShopContainer/VBoxContainer/TabContainer/Paint/PaintList
@onready var exhaust_list = $MainContainer/ShopContainer/VBoxContainer/TabContainer/Exhaust/ExhaustList
@onready var wings_list = $MainContainer/ShopContainer/VBoxContainer/TabContainer/Wings/WingsList
@onready var drones_list = $MainContainer/ShopContainer/VBoxContainer/TabContainer/Drones/DronesList
@onready var main_tab_container = $MainContainer/ShopContainer/VBoxContainer/TabContainer
@onready var description_label = $MainContainer/ShopContainer/VBoxContainer/DescriptionLabel
@onready var buy_button = $MainContainer/ShopContainer/VBoxContainer/ButtonContainer/BuyButton
@onready var resources_label = $ResourcesLabel
@onready var preview_area = $MainContainer/PreviewContainer/VBoxContainer/PreviewArea
@onready var preview_rocket = $MainContainer/PreviewContainer/VBoxContainer/PreviewArea/SubViewport/PreviewRocket

# Preview rocket instance
var preview_rocket_instance = null

# Current state
var current_tab = 0
var selected_item = null
var selected_cosmetics = {
	"paint": null,
	"exhaust": null,
	"wings": null
}

func _ready():
	# Populate item lists
	populate_paint_list()
	populate_exhaust_list()
	populate_wings_list()
	populate_drones_list()
	
	# Update resources display
	update_resources_display()
	
	# Initialize preview rocket
	initialize_preview_rocket()

func initialize_preview_rocket():
	# Load the rocket scene
	var rocket_scene = load("res://Scenes/GameObjects/Rocket.tscn")
	if rocket_scene:
		# Instance the rocket
		preview_rocket_instance = rocket_scene.instantiate()
		preview_rocket_instance.name = "PreviewRocketInstance"
		
		# Add it to the preview area
		preview_rocket.add_child(preview_rocket_instance)
		
		# Disable physics and other unnecessary features
		if preview_rocket_instance.has_method("set_physics_process"):
			preview_rocket_instance.set_physics_process(false)
		
		# Set a default scale for the preview
		preview_rocket_instance.scale = Vector2(0.8, 0.8)
		
		# Clear any existing cosmetics
		if preview_rocket_instance.has_method("clear_cosmetics"):
			preview_rocket_instance.clear_cosmetics()
	
	# Add stars to the background
	add_stars_to_preview()

func add_stars_to_preview():
	# Create a simple star field
	var star_count = 50
	var viewport_size = preview_area.get_viewport_rect().size
	
	for i in range(star_count):
		var star = ColorRect.new()
		star.size = Vector2(2, 2)
		star.position = Vector2(
			randf_range(0, viewport_size.x),
			randf_range(0, viewport_size.y)
		)
		star.color = Color(1, 1, 1, randf_range(0.3, 1.0))
		preview_rocket.add_child(star)
		
		# Add a simple twinkle animation
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(star, "color:a", randf_range(0.1, 0.3), randf_range(0.5, 2.0))
		tween.tween_property(star, "color:a", randf_range(0.5, 1.0), randf_range(0.5, 2.0))

func populate_paint_list():
	paint_list.clear()
	
	for item in paint_items:
		paint_list.add_item(item.name + " - G:" + str(item.cost.gas) + " S:" + str(item.cost.scrap))

func populate_exhaust_list():
	exhaust_list.clear()
	
	for item in exhaust_items:
		exhaust_list.add_item(item.name + " - G:" + str(item.cost.gas) + " S:" + str(item.cost.scrap))

func populate_wings_list():
	wings_list.clear()
	
	for item in wings_items:
		wings_list.add_item(item.name + " - G:" + str(item.cost.gas) + " S:" + str(item.cost.scrap))

func populate_drones_list():
	drones_list.clear()
	
	for item in drone_items:
		drones_list.add_item(item.name + " - G:" + str(item.cost.gas) + " S:" + str(item.cost.scrap))

func update_resources_display():
	var user_id = DataHandler.get_user_id()
	var materials = await DataHandler.get_user_materials(user_id)
	
	resources_label.text = "Gas: " + str(materials.get("gas", 0)) + " | Scrap: " + str(materials.get("scrap", 0))

func update_rocket_preview(cosmetic_id: String):
	if not preview_rocket_instance:
		return
		
	# Clear existing cosmetics
	if preview_rocket_instance.has_method("clear_cosmetics"):
		preview_rocket_instance.clear_cosmetics()
	
	# Apply the selected cosmetic
	if preview_rocket_instance.has_method("apply_cosmetic"):
		preview_rocket_instance.apply_cosmetic(cosmetic_id)
		
		# If it's a gold trim, we can also apply a red or blue base color
		if cosmetic_id == "gold_trim":
			# Check if the user already has red or blue rocket
			var user_id = DataHandler.get_user_id()
			var user_cosmetics = await DataHandler.get_user_cosmetics(user_id)
			
			if user_cosmetics.has("red_rocket") and user_cosmetics["red_rocket"]:
				preview_rocket_instance.apply_cosmetic("red_rocket")
			elif user_cosmetics.has("blue_rocket") and user_cosmetics["blue_rocket"]:
				preview_rocket_instance.apply_cosmetic("blue_rocket")

func _on_paint_list_item_selected(index):
	selected_item = paint_items[index]
	description_label.text = selected_item.description
	
	# Update the rocket preview
	update_rocket_preview(selected_item.id)
	
	check_if_can_afford(selected_item)

func _on_exhaust_list_item_selected(index):
	selected_item = exhaust_items[index]
	description_label.text = selected_item.description
	
	# Update the rocket preview
	update_rocket_preview(selected_item.id)
	
	check_if_can_afford(selected_item)

func _on_wings_list_item_selected(index):
	selected_item = wings_items[index]
	description_label.text = selected_item.description
	
	# Update the rocket preview
	update_rocket_preview(selected_item.id)
	
	check_if_can_afford(selected_item)

func _on_drones_list_item_selected(index):
	selected_item = drone_items[index]
	description_label.text = selected_item.description
	
	# Clear the rocket preview for drones
	if preview_rocket_instance and preview_rocket_instance.has_method("clear_cosmetics"):
		preview_rocket_instance.clear_cosmetics()
	
	check_if_can_afford(selected_item)

func check_if_can_afford(item):
	# Check if player can afford this item
	var user_id = DataHandler.get_user_id()
	var materials = await DataHandler.get_user_materials(user_id)
	
	var can_afford = materials.get("gas", 0) >= item.cost.gas and materials.get("scrap", 0) >= item.cost.scrap
	buy_button.disabled = not can_afford

func _on_tab_container_tab_changed(tab):
	current_tab = tab
	selected_item = null
	description_label.text = "Select an item to see its description!"
	buy_button.disabled = true
	
	# Clear the rocket preview when switching tabs
	if preview_rocket_instance and preview_rocket_instance.has_method("clear_cosmetics"):
		preview_rocket_instance.clear_cosmetics()

func _on_buy_button_pressed():
	if selected_item == null:
		return
		
	var user_id = DataHandler.get_user_id()
	var materials = await DataHandler.get_user_materials(user_id)
	
	# Deduct resources
	var new_gas = materials.get("gas", 0) - selected_item.cost.gas
	var new_scrap = materials.get("scrap", 0) - selected_item.cost.scrap
	
	# Update materials in DataHandler
	await DataHandler.store_materials(user_id, new_gas, new_scrap)
	
	# Handle the purchase based on what was bought
	if current_tab < 3: # Paint, Exhaust, or Wings
		purchase_cosmetic(user_id, selected_item)
	else: # Drones
		purchase_drone(user_id, selected_item)
	
	# Update UI
	update_resources_display()
	
	# Disable buy button until next selection
	buy_button.disabled = true
	
	# Show success message
	description_label.text = "Successfully purchased " + selected_item.name + "!"

func purchase_cosmetic(user_id, cosmetic_item):
	# In a real implementation, you would store the purchased cosmetic
	# For example:
	var user_cosmetics = await DataHandler.get_user_cosmetics(user_id) if DataHandler.has_method("get_user_cosmetics") else {}
	user_cosmetics[cosmetic_item.id] = true
	
	# You might need to add a new function to DataHandler for this
	if DataHandler.has_method("store_user_cosmetics"):
		await DataHandler.store_user_cosmetics(user_id, user_cosmetics)

func purchase_drone(user_id, drone_item):
	# In a real implementation, you would store the purchased drone
	# For example:
	var user_drones = DataHandler.get_user_drones(user_id) if DataHandler.has_method("get_user_drones") else {}
	if not user_drones.has(drone_item.id):
		user_drones[drone_item.id] = 1
	else:
		user_drones[drone_item.id] += 1
	
	# You might need to add a new function to DataHandler for this
	if DataHandler.has_method("store_user_drones"):
		await DataHandler.store_user_drones(user_id, user_drones)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn")

func load_owned_cosmetics():
	# Get player's owned cosmetics from DataHandler
	var user_id = DataHandler.get_user_id()
	var owned_cosmetics = await DataHandler.get_user_cosmetics(user_id)
	
	# Initialize selected cosmetics based on what the player owns
	for cosmetic_id in owned_cosmetics:
		if owned_cosmetics[cosmetic_id]:
			# Determine which category this cosmetic belongs to
			if cosmetic_id in ["red_rocket", "blue_rocket", "gold_trim"]:
				selected_cosmetics["paint"] = cosmetic_id
			elif cosmetic_id in ["blue_exhaust", "green_exhaust", "purple_exhaust"]:
				selected_cosmetics["exhaust"] = cosmetic_id
			elif cosmetic_id in ["small_wings", "large_wings", "bat_wings"]:
				selected_cosmetics["wings"] = cosmetic_id