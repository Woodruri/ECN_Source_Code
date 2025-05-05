extends Control

# Cosmetic items by category
var paint_items = [
	{
		"id": "red_rocket",
		"name": "Red Rocket Paint",
		"description": "Red paint job for your rocket.",
		"preview_image": null
	},
	{
		"id": "blue_rocket",
		"name": "Blue Rocket Paint",
		"description": "Blue paint job for your rocket.",
		"preview_image": null
	},
	{
		"id": "gold_trim",
		"name": "Gold Trim Package",
		"description": "Flex that money with GOLD.",
		"preview_image": null
	}
]

var exhaust_items = [
	{
		"id": "blue_exhaust",
		"name": "Blue Exhaust",
		"description": "Blue exhaust particles for your rocket.",
		"preview_image": null
	},
	{
		"id": "green_exhaust",
		"name": "Green Exhaust",
		"description": "Green exhaust particles for your rocket.",
		"preview_image": null
	},
	{
		"id": "purple_exhaust",
		"name": "Purple Exhaust",
		"description": "Purple exhaust particles for your rocket.",
		"preview_image": null
	}
]

var wings_items = [
	{
		"id": "small_wings",
		"name": "Small Wings",
		"description": "Small decorative wings for your rocket.",
		"preview_image": null
	},
	{
		"id": "large_wings",
		"name": "Large Wings",
		"description": "Large decorative wings for your rocket.",
		"preview_image": null
	},
	{
		"id": "bat_wings",
		"name": "Bat Wings",
		"description": "Bat-like wings for your rocket.",
		"preview_image": null
	}
]

# UI References
@onready var paint_list = $MainContainer/CustomizeContainer/VBoxContainer/TabContainer/Paint/PaintList
@onready var exhaust_list = $MainContainer/CustomizeContainer/VBoxContainer/TabContainer/Exhaust/ExhaustList
@onready var wings_list = $MainContainer/CustomizeContainer/VBoxContainer/TabContainer/Wings/WingsList
@onready var main_tab_container = $MainContainer/CustomizeContainer/VBoxContainer/TabContainer
@onready var description_label = $MainContainer/CustomizeContainer/VBoxContainer/DescriptionLabel
@onready var preview_area = $MainContainer/PreviewContainer/VBoxContainer/PreviewArea
@onready var preview_rocket = $MainContainer/PreviewContainer/VBoxContainer/PreviewArea/SubViewport/PreviewRocket

# Preview rocket instance
var preview_rocket_instance = null

# Current state
var current_tab = 0
var selected_item = null

# Selected cosmetics by category
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
	
	# Initialize preview rocket
	initialize_preview_rocket()
	
	# Load player's owned cosmetics
	load_owned_cosmetics()
	
	# Add stars to the background
	add_stars_to_preview()

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
		paint_list.add_item(item.name)

func populate_exhaust_list():
	exhaust_list.clear()
	
	for item in exhaust_items:
		exhaust_list.add_item(item.name)

func populate_wings_list():
	wings_list.clear()
	
	for item in wings_items:
		wings_list.add_item(item.name)

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
	
	# Update the preview with the selected cosmetics
	update_rocket_preview()
	
	# Update the item lists to show the selected items
	update_item_list_selections()

func update_item_list_selections():
	# Clear all selections first
	paint_list.deselect_all()
	exhaust_list.deselect_all()
	wings_list.deselect_all()
	
	# Select the appropriate items based on selected_cosmetics
	if selected_cosmetics["paint"]:
		for i in range(paint_items.size()):
			if paint_items[i]["id"] == selected_cosmetics["paint"]:
				paint_list.select(i)
				break
	
	if selected_cosmetics["exhaust"]:
		for i in range(exhaust_items.size()):
			if exhaust_items[i]["id"] == selected_cosmetics["exhaust"]:
				exhaust_list.select(i)
				break
	
	if selected_cosmetics["wings"]:
		for i in range(wings_items.size()):
			if wings_items[i]["id"] == selected_cosmetics["wings"]:
				wings_list.select(i)
				break

func update_rocket_preview():
	if not preview_rocket_instance:
		return
		
	# Clear existing cosmetics
	if preview_rocket_instance.has_method("clear_cosmetics"):
		preview_rocket_instance.clear_cosmetics()
	
	# Apply the selected cosmetics
	if preview_rocket_instance.has_method("apply_cosmetic"):
		# Apply paint first (if any)
		if selected_cosmetics["paint"]:
			preview_rocket_instance.apply_cosmetic(selected_cosmetics["paint"])
		
		# Apply exhaust (if any)
		if selected_cosmetics["exhaust"]:
			preview_rocket_instance.apply_cosmetic(selected_cosmetics["exhaust"])
		
		# Apply wings (if any)
		if selected_cosmetics["wings"]:
			preview_rocket_instance.apply_cosmetic(selected_cosmetics["wings"])

func _on_paint_list_item_selected(index):
	selected_item = paint_items[index]
	description_label.text = selected_item.description
	
	# Update the selected cosmetic for this category
	selected_cosmetics["paint"] = selected_item.id
	
	# Update the rocket preview
	update_rocket_preview()

func _on_exhaust_list_item_selected(index):
	selected_item = exhaust_items[index]
	description_label.text = selected_item.description
	
	# Update the selected cosmetic for this category
	selected_cosmetics["exhaust"] = selected_item.id
	
	# Update the rocket preview
	update_rocket_preview()

func _on_wings_list_item_selected(index):
	selected_item = wings_items[index]
	description_label.text = selected_item.description
	
	# Update the selected cosmetic for this category
	selected_cosmetics["wings"] = selected_item.id
	
	# Update the rocket preview
	update_rocket_preview()

func _on_tab_container_tab_changed(tab):
	current_tab = tab
	selected_item = null
	description_label.text = "Select a cosmetic to see its description!"

func _on_apply_button_pressed():
	# Save the selected cosmetics to the player's data
	var user_id = DataHandler.get_user_id()
	var user_cosmetics = await DataHandler.get_user_cosmetics(user_id)
	
	# First, clear all cosmetics
	for cosmetic_id in user_cosmetics:
		user_cosmetics[cosmetic_id] = false
	
	# Then set only the selected ones to true
	if selected_cosmetics["paint"]:
		user_cosmetics[selected_cosmetics["paint"]] = true
	
	if selected_cosmetics["exhaust"]:
		user_cosmetics[selected_cosmetics["exhaust"]] = true
	
	if selected_cosmetics["wings"]:
		user_cosmetics[selected_cosmetics["wings"]] = true
	
	# Save the updated cosmetics
	DataHandler.store_user_cosmetics(user_id, user_cosmetics)
	
	# Show success message
	show_success_message("Cosmetics applied and saved successfully!")
	
	print("Cosmetics applied and saved for user: ", user_id)

func show_success_message(message: String):
	# Create a temporary label to show the success message
	var success_label = Label.new()
	success_label.text = message
	success_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	success_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	success_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green text
	success_label.add_theme_font_size_override("font_size", 24)
	
	# Position the label in the center of the screen
	success_label.position = Vector2(get_viewport_rect().size.x / 2 - 150, get_viewport_rect().size.y / 2 - 20)
	success_label.size = Vector2(300, 40)
	
	# Add the label to the scene
	add_child(success_label)
	
	# Create a timer to remove the label after 2 seconds
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func(): success_label.queue_free())

func _on_reset_button_pressed():
	# Reset to currently saved cosmetics
	var user_id = DataHandler.get_user_id()
	var user_cosmetics = await DataHandler.get_user_cosmetics(user_id)
	
	# Clear all selections
	selected_cosmetics = {
		"paint": null,
		"exhaust": null,
		"wings": null
	}
	
	# Set selections based on what the player owns
	for cosmetic_id in user_cosmetics:
		if user_cosmetics[cosmetic_id]:
			# Determine which category this cosmetic belongs to
			if cosmetic_id in ["red_rocket", "blue_rocket", "gold_trim"]:
				selected_cosmetics["paint"] = cosmetic_id
			elif cosmetic_id in ["blue_exhaust", "green_exhaust", "purple_exhaust"]:
				selected_cosmetics["exhaust"] = cosmetic_id
			elif cosmetic_id in ["small_wings", "large_wings", "bat_wings"]:
				selected_cosmetics["wings"] = cosmetic_id
	
	# Update the UI
	update_item_list_selections()
	
	# Update the preview
	update_rocket_preview()
	
	# Reset description
	description_label.text = "Select a cosmetic to see its description!"

func _on_back_button_pressed():
	# Return to the previous screen
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn")
