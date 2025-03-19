extends Control

@onready var global_list = $MarginContainer/VBoxContainer/LeaderboardContainer/GlobalContainer/GlobalList
@onready var planet_list = $MarginContainer/VBoxContainer/LeaderboardContainer/PlanetContainer/PlanetList
@onready var planet_selector = $MarginContainer/VBoxContainer/LeaderboardContainer/PlanetContainer/PlanetSelector
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel

var current_planet = "Planet_1"

func _ready():
	print("Initializing leaderboard...")
	
	# Wait one frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Load all data first
	DataHandler.load_all_data()
	
	# Populate planet selector
	var planets = ["Planet_1", "Planet_2", "Planet_3"]
	for planet in planets:
		planet_selector.add_item(planet)
	
	# Connect signals
	planet_selector.item_selected.connect(_on_planet_selected)
	
	# Initial display
	update_leaderboards()

func add_entry_to_list(list: ItemList, entry: Dictionary, is_current_user: bool = false):
	var text = "%d. %s - %d points" % [
		entry["rank"],
		entry["name"],
		entry["points"]
	]
	
	if is_current_user:
		# Add asterisks and make text bold for current user
		text = "★ " + text + " ★"
	
	var idx = list.add_item(text)
	
	if is_current_user:
		# Highlight current user's entry
		list.set_item_custom_fg_color(idx, Color(1, 0.8, 0))  # Golden yellow color
		list.set_item_custom_bg_color(idx, Color(0.2, 0.2, 0.2))  # Dark background

func update_leaderboards():
	print("Updating leaderboards...")
	
	if not is_instance_valid(global_list) or not is_instance_valid(planet_list):
		print("Lists not ready yet")
		return
	
	var current_user_id = DataHandler.get_user_id()
	
	# Update global leaderboard
	global_list.clear()
	var global_rankings = DataHandler.get_leaderboard(999)  # Get all rankings to find user's position
	print("Global rankings:", global_rankings)
	
	if global_rankings.is_empty():
		global_list.add_item("No players found")
	else:
		var current_user_rank = null
		var current_user_entry = null
		
		# Find current user's rank and entry
		for entry in global_rankings:
			if entry["id"] == current_user_id:
				current_user_rank = entry["rank"]
				current_user_entry = entry
				break
		
		# Show top 10
		var shown_user = false
		for i in range(min(10, global_rankings.size())):
			var entry = global_rankings[i]
			var is_current_user = entry["id"] == current_user_id
			add_entry_to_list(global_list, entry, is_current_user)
			if is_current_user:
				shown_user = true
		
		# If user not in top 10, add separator and their position
		if not shown_user and current_user_entry != null:
			global_list.add_item("-------------------")
			add_entry_to_list(global_list, current_user_entry, true)
	
	# Update planet leaderboards
	planet_list.clear()
	var planet_rankings = DataHandler.get_planet_leaderboard(current_planet, 999)  # Get all rankings for current planet
	print("Planet rankings for %s:" % current_planet, planet_rankings)
	
	if planet_rankings.is_empty():
		planet_list.add_item("No players on %s" % current_planet)
	else:
		var current_user_rank = null
		var current_user_entry = null
		
		# Find current user's rank and entry
		for entry in planet_rankings:
			if entry["id"] == current_user_id:
				current_user_rank = entry["rank"]
				current_user_entry = entry
				break
		
		# Show top 10
		var shown_user = false
		for i in range(min(10, planet_rankings.size())):
			var entry = planet_rankings[i]
			var is_current_user = entry["id"] == current_user_id
			add_entry_to_list(planet_list, entry, is_current_user)
			if is_current_user:
				shown_user = true
		
		# If user not in top 10, add separator and their position
		if not shown_user and current_user_entry != null:
			planet_list.add_item("-------------------")
			add_entry_to_list(planet_list, current_user_entry, true)
	
	# Update title
	title_label.text = "Leaderboard - %s" % current_planet

func _on_planet_selected(index: int):
	current_planet = planet_selector.get_item_text(index)
	update_leaderboards()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/menu.tscn")
