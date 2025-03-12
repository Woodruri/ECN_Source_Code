extends Control

@onready var global_list = $LeaderboardContainer/GlobalContainer/GlobalList
@onready var planet_list = $LeaderboardContainer/PlanetContainer/PlanetList
@onready var planet_selector = $LeaderboardContainer/PlanetContainer/PlanetSelector
@onready var title_label = $TitleLabel

var current_planet = "Planet_1"

func _ready():
	# Populate planet selector
	var planets = ["Planet_1", "Planet_2", "Planet_3"]
	for planet in planets:
		planet_selector.add_item(planet)
	
	# Connect signals
	planet_selector.item_selected.connect(_on_planet_selected)
	
	# Initial display
	update_leaderboards()

func update_leaderboards():
	# Update global leaderboard
	global_list.clear()
	var global_rankings = DataHandler.get_leaderboard(10)  # Top 10 global
	
	for entry in global_rankings:
		global_list.add_item(
			"%d. %s | Points: %d" % [
				entry["rank"],
				entry["name"],
				entry["points"]
			]
		)
	
	# Update planet leaderboards
	planet_list.clear()
	var planet_rankings = DataHandler.get_planet_leaderboard(current_planet, 10)  # Top 10 per planet
	
	for entry in planet_rankings:
		planet_list.add_item(
			"%d. %s | Points: %d" % [
				entry["rank"],
				entry["name"],
				entry["points"]
			]
		)
	
	# Update title
	title_label.text = "Leaderboard - %s" % current_planet

func _on_planet_selected(index: int):
	current_planet = planet_selector.get_item_text(index)
	update_leaderboards()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn")
