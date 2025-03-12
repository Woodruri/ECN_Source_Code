extends Control

var shop_items = {
	"extra_gas": {
		"name": "Extra Gas Tank",
		"description": "Increases gas capacity by 50",
		"cost": {"scrap": 100},
		"effect": func(user_id): 
			var materials = DataHandler.get_user_materials(user_id)
			materials["gas"] = materials.get("gas", 0) + 50
			DataHandler.store_materials(user_id, materials["gas"], materials.get("scrap", 0))
	},
	"gas_efficiency": {
		"name": "Improved Engine",
		"description": "Reduces gas cost for travel by 20%",
		"cost": {"scrap": 200},
		"effect": func(user_id):
			var current_upgrades = DataHandler.get_user_upgrades(user_id)
			current_upgrades["gas_efficiency"] = current_upgrades.get("gas_efficiency", 0) + 0.2
			DataHandler.store_upgrades(user_id, current_upgrades)
	},
	"point_multiplier": {
		"name": "Point Booster",
		"description": "Increases points earned by 10%",
		"cost": {"scrap": 300},
		"effect": func(user_id):
			var current_upgrades = DataHandler.get_user_upgrades(user_id)
			current_upgrades["point_multiplier"] = current_upgrades.get("point_multiplier", 1.0) + 0.1
			DataHandler.store_upgrades(user_id, current_upgrades)
	}
}

@onready var item_list = $ShopContainer/ItemList
@onready var description_label = $ShopContainer/DescriptionLabel
@onready var buy_button = $ShopContainer/BuyButton
@onready var resources_label = $ResourcesLabel

var selected_item = null

func _ready():
	update_resources_display()
	populate_shop_items()
	
	# Connect signals
	item_list.item_selected.connect(_on_item_selected)
	buy_button.pressed.connect(_on_buy_pressed)

func populate_shop_items():
	item_list.clear()
	for item_id in shop_items:
		var item = shop_items[item_id]
		item_list.add_item(item["name"])

func update_resources_display():
	var user_id = DataHandler.get_user_id()
	var materials = DataHandler.get_user_materials(user_id)
	resources_label.text = "Gas: %d | Scrap: %d" % [
		materials.get("gas", 0),
		materials.get("scrap", 0)
	]

func _on_item_selected(index: int):
	var item_id = shop_items.keys()[index]
	selected_item = shop_items[item_id]
	
	# Update description
	description_label.text = selected_item["description"] + "\nCost: " + str(selected_item["cost"]["scrap"]) + " scrap"
	
	# Enable buy button if can afford
	var user_id = DataHandler.get_user_id()
	var materials = DataHandler.get_user_materials(user_id)
	buy_button.disabled = materials.get("scrap", 0) < selected_item["cost"]["scrap"]

func _on_buy_pressed():
	if not selected_item:
		return
		
	var user_id = DataHandler.get_user_id()
	var materials = DataHandler.get_user_materials(user_id)
	
	# Check if can afford
	if materials.get("scrap", 0) < selected_item["cost"]["scrap"]:
		return
	
	# Deduct cost
	materials["scrap"] = materials["scrap"] - selected_item["cost"]["scrap"]
	DataHandler.store_materials(user_id, materials.get("gas", 0), materials["scrap"])
	
	# Apply effect
	selected_item["effect"].call(user_id)
	
	# Update displays
	update_resources_display()
	_on_item_selected(item_list.get_selected_items()[0])

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn") 