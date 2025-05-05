extends Control

@onready var global_list = $MarginContainer/VBoxContainer/LeaderboardContainer/GlobalContainer/GlobalList
@onready var planet_list = $MarginContainer/VBoxContainer/LeaderboardContainer/PlanetContainer/PlanetList
@onready var planet_selector = $MarginContainer/VBoxContainer/LeaderboardContainer/PlanetContainer/PlanetSelector
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var user_selector = $MarginContainer/VBoxContainer/UserSelectorContainer/UserSelector

var current_planet = "Planet_1"

func _ready():
	print("Initializing leaderboard...")
	
	# Wait one frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Load all data first
	await DataHandler.import_all_data_from_file("user://data.json")
	
	# Populate user selector
	populate_user_selector()
	
	# Populate planet selector
	var planets = ["Planet_1", "Planet_2", "Planet_3"]
	for planet in planets:
		planet_selector.add_item(planet)
	
	# Connect signals
	planet_selector.item_selected.connect(_on_planet_selected)
	user_selector.item_selected.connect(_on_user_selected)
	
	# Initial display
	update_leaderboards()

func populate_user_selector():
	user_selector.clear()
	
	# Get current user data
	var current_user_id = DataHandler.get_user_id()
	var current_user_data = DataHandler.get_employee_from_id(current_user_id)
	
	# Add current user to the dropdown
	var current_user_text = "%s (%s)" % [current_user_data.get("name", "Player"), current_user_id]
	user_selector.add_item(current_user_text)
	user_selector.set_item_metadata(0, current_user_id)
	
	# Add other players from game state
	var other_players = DataHandler.get_persistent_game_state().get("other_players", {})
	var index = 1
	
	for player_id in other_players:
		var player_text = "Player (%s)" % player_id
		user_selector.add_item(player_text)
		user_selector.set_item_metadata(index, player_id)
		index += 1
	
	# Set the current user as selected
	user_selector.select(0)

func _on_user_selected(index: int):
	var selected_id = user_selector.get_item_metadata(index)
	DataHandler.set_user_id(selected_id)
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

func update_leaderboards() -> void:
	# Check if the lists are valid
	if not is_instance_valid(global_list) or not is_instance_valid(planet_list):
		print("Error: Leaderboard lists not found")
		return
		
	# Clear existing entries
	global_list.clear()
	planet_list.clear()
	
	var current_user_id = DataHandler.get_user_id()
	var game_state = DataHandler.get_persistent_game_state()
	var current_planet = game_state.get("current_planet", "Planet_1")
	print("Current user: %s, Current planet: %s" % [current_user_id, current_planet])
	
	# Update global leaderboard
	print("Fetching global leaderboard...")
	var global_rankings = await DataHandler.get_global_leaderboard(999)  # Get all rankings to find user's position
	print("Global rankings count: %d" % global_rankings.size())
	
	# Debug: Print all rankings
	print("DEBUG: All global rankings:")
	for entry in global_rankings:
		print("  - %s: %d points (rank %d)" % [entry["name"], entry["points"], entry["rank"]])
	
	if global_rankings.is_empty():
		print("No global rankings found")
		global_list.add_item("No players found")
	else:
		var current_user_rank = null
		var current_user_entry = null
		
		# Find current user's rank and entry
		for entry in global_rankings:
			if entry["id"] == current_user_id:
				current_user_rank = entry["rank"]
				current_user_entry = entry
				print("Found current user in global rankings: rank %d, points %d" % [current_user_rank, entry["points"]])
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
	print("Fetching planet leaderboard for %s..." % current_planet)
	var planet_rankings = await DataHandler.get_planet_leaderboard(current_planet, 999)  # Get all rankings for current planet
	print("Planet rankings count: %d" % planet_rankings.size())
	
	# Debug: Print all planet rankings
	print("DEBUG: All planet rankings for %s:" % current_planet)
	for entry in planet_rankings:
		print("  - %s: %d points (rank %d)" % [entry["name"], entry["points"], entry["rank"]])
	
	if planet_rankings.is_empty():
		print("No planet rankings found")
		planet_list.add_item("No players on %s" % current_planet)
	else:
		var current_user_rank = null
		var current_user_entry = null
		
		# Find current user's rank and entry
		for entry in planet_rankings:
			if entry["id"] == current_user_id:
				current_user_rank = entry["rank"]
				current_user_entry = entry
				print("Found current user in planet rankings: rank %d, points %d" % [current_user_rank, entry["points"]])
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
	if is_instance_valid(title_label):
		title_label.text = "Leaderboard - %s" % current_planet

func _on_planet_selected(index: int):
	current_planet = planet_selector.get_item_text(index)
	update_leaderboards()

func _on_back_button_pressed() -> void:
	print("Back button pressed - returning to menu...")
	
	# Try to change scene immediately
	var error = get_tree().change_scene_to_file("res://Scenes/Menus/menu.tscn")
	if error != OK:
		print("Error changing to menu scene. Error code: ", error)
		# Try alternative scene path
		error = get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn")
		if error != OK:
			print("Error with alternative scene path. Error code: ", error)
			# Try loading from the packed scene
			var packed_scene = load("res://Scenes/Menus/menu.tscn")
			if packed_scene != null:
				error = get_tree().change_scene_to_packed(packed_scene)
				if error != OK:
					print("Error with packed scene loading. Error code: ", error)
					return
			else:
				print("Failed to load menu scene")
				return
	
	print("Successfully changed to menu scene")
