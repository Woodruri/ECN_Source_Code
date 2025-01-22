extends Control

@onready var id_input: LineEdit = $VBoxContainer/IDInput


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_submit_button_pressed() -> void:
	#takes input ID and loads the data, then allows the user to adjust those numbers
	var id = id_input.text.strip_edges()
	
	if id == "":
		print("Please enter an ID!")
		return
	
	var employee_obj = DataHandler.get_employee_from_id(id)
	var materials = DataHandler.retrieve_materials(id)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/options.tscn")
