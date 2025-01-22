extends Control


'''# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass'''


func _on_load_data_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/load_data.tscn")


func _on_create_player_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/create_user.tscn")


func _on_create_ecn_button_pressed() -> void:
	pass


func _on_adjust_employee_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/adjust_employee.tscn")


func _on_adjust_worlds_button_pressed() -> void:
	pass # Replace with function body.

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn")
