extends Control

# Shop items by category
var cosmetics_items = [
	{
		"id": "red_rocket",
		"name": "Red Rocket Paint",
		"description": "Red paint job for your rocket.",
		"cost": {"gas": 100, "scrap": 50},
		"preview_image": null # Could be a path to an image resource
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
@onready var cosmetics_list = $ShopContainer/TabContainer/Cosmetics/CosmeticsList
@onready var drones_list = $ShopContainer/TabContainer/Drones/DronesList
@onready var tab_container = $ShopContainer/TabContainer
@onready var description_label = $ShopContainer/DescriptionLabel
@onready var buy_button = $ShopContainer/BuyButton
@onready var resources_label = $ResourcesLabel

var current_tab = 0
var selected_item = null

func _ready():
	# Populate item lists
	populate_cosmetics_list()
	populate_drones_list()
	
	# Update resources display
	update_resources_display()

func populate_cosmetics_list():
	cosmetics_list.clear()
	
	for item in cosmetics_items:
		cosmetics_list.add_item(item.name + " - G:" + str(item.cost.gas) + " S:" + str(item.cost.scrap))

func populate_drones_list():
	drones_list.clear()
	
	for item in drone_items:
		drones_list.add_item(item.name + " - G:" + str(item.cost.gas) + " S:" + str(item.cost.scrap))

func update_resources_display():
	var user_id = DataHandler.get_user_id()
	var materials = DataHandler.get_user_materials(user_id)
	
	resources_label.text = "Gas: " + str(materials.get("gas", 0)) + " | Scrap: " + str(materials.get("scrap", 0))

func _on_cosmetics_list_item_selected(index):
	selected_item = cosmetics_items[index]
	description_label.text = selected_item.description
	
	check_if_can_afford(selected_item)

func _on_drones_list_item_selected(index):
	selected_item = drone_items[index]
	description_label.text = selected_item.description
	
	check_if_can_afford(selected_item)

func check_if_can_afford(item):
	# Check if player can afford this item
	var user_id = DataHandler.get_user_id()
	var materials = DataHandler.get_user_materials(user_id)
	
	var can_afford = materials.get("gas", 0) >= item.cost.gas and materials.get("scrap", 0) >= item.cost.scrap
	buy_button.disabled = not can_afford

func _on_tab_container_tab_changed(tab):
	current_tab = tab
	selected_item = null
	description_label.text = "Select an item to see its description!"
	buy_button.disabled = true

func _on_buy_button_pressed():
	if selected_item == null:
		return
		
	var user_id = DataHandler.get_user_id()
	var materials = DataHandler.get_user_materials(user_id)
	
	# Deduct resources
	var new_gas = materials.get("gas", 0) - selected_item.cost.gas
	var new_scrap = materials.get("scrap", 0) - selected_item.cost.scrap
	
	# Update materials in DataHandler
	DataHandler.store_materials(user_id, new_gas, new_scrap)
	
	# Handle the purchase based on what was bought
	if current_tab == 0: # Cosmetics
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
	var user_cosmetics = DataHandler.get_user_cosmetics(user_id) if DataHandler.has_method("get_user_cosmetics") else {}
	user_cosmetics[cosmetic_item.id] = true
	
	# You might need to add a new function to DataHandler for this
	if DataHandler.has_method("store_user_cosmetics"):
		DataHandler.store_user_cosmetics(user_id, user_cosmetics)

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
		DataHandler.store_user_drones(user_id, user_drones)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn")
