extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_load_leaderboard_button_pressed() -> void:
	#load a data structure with leaderboard, and then populate this VBox with that data
	var leaderboard = DataHandler.get_leaderboard(10)
	
	# Want it to be sorted s.t. [0] is the top scorer, [1] is 2, etc.
	for elem in leaderboard:
		print(elem)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/options.tscn")
