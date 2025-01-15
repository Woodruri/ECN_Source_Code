extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/game.tscn")


func _on_allocate_points_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/allocate_points.tscn")


func _on_leaderboard_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/leaderboard.tscn")


func _on_shop_button_pressed() -> void:
	#TODO get_tree().change_scene_to_file("res://Scenes/game.tscn")
	pass


func _on_customize_ship_button_pressed() -> void:
	#TODO get_tree().change_scene_to_file("res://Scenes/game.tscn")
	pass


func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/options.tscn")


#exit game
func _on_exit_button_pressed() -> void:
	get_tree().quit()
