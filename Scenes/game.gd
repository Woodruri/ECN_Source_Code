extends Node2D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#input reciever
func _input(event):
	pass

func add_to_leaderboard(EmployeeName, points,id, hat):
	var planet = $Planet_1
	planet.add_to_leaderboard(EmployeeName, points, id, hat)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn")
