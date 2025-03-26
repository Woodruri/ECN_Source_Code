extends Control

var RocketScene = preload("res://Scenes/GameObjects/Rocket.tscn")
var rocket_instance
var selected_cosmetics = {}

# UI references
@onready var ship_viewport = $ShipPreviewContainer/SubViewport
@onready var cosmetics_grid = $CosmeticsPanel/ScrollContainer/CosmeticsGrid

func _ready():
	# Load the rocket into the viewport
	load_rocket_preview()
	
	# DEBUG: Give the player some cosmetics to test with
	debug_give_cosmetics()
	
	# Load player's owned cosmetics
	load_owned_cosmetics()
	
	# Connect button signals
	$ControlsContainer/ApplyButton.pressed.connect(_on_apply_button_pressed)
	$ControlsContainer/ResetButton.pressed.connect(_on_reset_button_pressed)
	$ControlsContainer/BackButton.pressed.connect(_on_back_button_pressed)

func load_rocket_preview():
	# Remove any existing rocket instance
	for child in ship_viewport.get_children():
		child.queue_free()
	
	# Instance the rocket scene
	rocket_instance = RocketScene.instantiate()
	ship_viewport.add_child(rocket_instance)
	
	# Center the rocket in the viewport
	rocket_instance.position = Vector2(ship_viewport.size.x / 2, ship_viewport.size.y / 2)

func load_owned_cosmetics():
	# Clear existing items
	for child in cosmetics_grid.get_children():
		child.queue_free()
	
	# Get player's owned cosmetics from DataHandler
	var user_id = DataHandler.get_user_id()
	var owned_cosmetics = DataHandler.get_user_cosmetics(user_id)
	
	# Get current applied cosmetics
	var current_cosmetics = DataHandler.get_user_cosmetics(user_id)
	selected_cosmetics = current_cosmetics.duplicate()
	
	# Create cosmetic options in the grid
	for cosmetic_id in owned_cosmetics:
		if owned_cosmetics[cosmetic_id]:
			# Create a cosmetic option
			create_cosmetic_option(cosmetic_id, current_cosmetics.get(cosmetic_id, false))

func create_cosmetic_option(cosmetic_id, is_active):
	# Find cosmetic info from the shop data
	var cosmetic_info = get_cosmetic_info(cosmetic_id)
	if not cosmetic_info:
		return
	
	# Create container for the cosmetic option
	var option = VBoxContainer.new()
	option.custom_minimum_size = Vector2(180, 100)
	# Store the cosmetic_id in metadata to reference later
	option.set_meta("cosmetic_id", cosmetic_id)
	cosmetics_grid.add_child(option)
	
	# Add cosmetic preview image (placeholder for now)
	var preview = TextureRect.new()
	preview.expand = true
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(80, 80)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	option.add_child(preview)
	
	# Add cosmetic name
	var name_label = Label.new()
	name_label.text = cosmetic_info.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	option.add_child(name_label)
	
	# Add checkbox for selection
	var checkbox = CheckBox.new()
	checkbox.text = "Use"
	checkbox.button_pressed = is_active
	checkbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	checkbox.name = "CheckBox" # Set a consistent name to find it later
	option.add_child(checkbox)
	
	# Connect checkbox to selection function
	checkbox.toggled.connect(_on_cosmetic_toggled.bind(cosmetic_id))

func get_cosmetic_info(cosmetic_id):
	# This should match the data structure in shop.gd
	var cosmetics_items = [
		{
			"id": "red_rocket",
			"name": "Red Rocket Paint",
			"description": "Red paint job for your rocket.",
			"cost": {"gas": 100, "scrap": 50}
		},
		{
			"id": "blue_rocket",
			"name": "Blue Rocket Paint",
			"description": "Blue paint job for your rocket.",
			"cost": {"gas": 100, "scrap": 50}
		},
		{
			"id": "gold_trim",
			"name": "Gold Trim Package",
			"description": "Flex that money with GOLD.",
			"cost": {"gas": 300, "scrap": 200}
		}
	]
	
	for item in cosmetics_items:
		if item.id == cosmetic_id:
			return item
	
	return null

func update_rocket_preview():
	# Update the rocket's appearance based on selected cosmetics
	if rocket_instance:
		# First clear all cosmetics
		rocket_instance.clear_cosmetics()
		
		# Apply each selected cosmetic
		for cosmetic_id in selected_cosmetics:
			if selected_cosmetics[cosmetic_id]:
				rocket_instance.apply_cosmetic(cosmetic_id)
				print("Applied cosmetic to preview: ", cosmetic_id)

func _on_cosmetic_toggled(is_toggled, cosmetic_id):
	selected_cosmetics[cosmetic_id] = is_toggled
	update_rocket_preview()

func _on_apply_button_pressed():
	# Save the selected cosmetics to the player's data
	var user_id = DataHandler.get_user_id()
	DataHandler.store_user_cosmetics(user_id, selected_cosmetics)
	print("Cosmetics applied and saved")

func _on_reset_button_pressed():
	# Reset to currently saved cosmetics
	var user_id = DataHandler.get_user_id()
	var current_cosmetics = DataHandler.get_user_cosmetics(user_id)
	selected_cosmetics = current_cosmetics.duplicate()
	
	# Update the UI checkboxes
	for child in cosmetics_grid.get_children():
		var checkbox = child.get_node_or_null("CheckBox")
		if checkbox and child.has_meta("cosmetic_id"):
			var cosmetic_id = child.get_meta("cosmetic_id")
			checkbox.button_pressed = selected_cosmetics.get(cosmetic_id, false)
	
	# Update the preview
	update_rocket_preview()

func _on_back_button_pressed():
	# Return to the previous screen
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn")

func debug_give_cosmetics():
	var user_id = DataHandler.get_user_id()
	var user_cosmetics = DataHandler.get_user_cosmetics(user_id)
	
	# Give the player all cosmetics for testing
	user_cosmetics["red_rocket"] = true
	user_cosmetics["blue_rocket"] = true
	user_cosmetics["gold_trim"] = true
	
	# Save these cosmetics
	DataHandler.store_user_cosmetics(user_id, user_cosmetics)
	print("DEBUG: Gave test cosmetics to player")
