extends Control

@onready var name_input: LineEdit = $VBoxContainer/NameBox/NameInput
@onready var id_input: LineEdit = $VBoxContainer/IDBox/IDInput
@onready var scrap_input: LineEdit = $VBoxContainer/ScrapBox/ScrapInput
@onready var gas_input: LineEdit = $VBoxContainer/GasBox/GasInput


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_submit_button_pressed() -> void:
	#Gets the info on the page and adds it to our JSON files
	var EmployeeName = name_input.text.strip_edges()
	var id = id_input.text.strip_edges()
	var scrap = int(scrap_input.text.strip_edges())
	var gas = int(gas_input.text.strip_edges())

	# Validate the inputs
	if "" in [EmployeeName, id, scrap, gas]:
		print("All fields must be filled out!")
		return

	# Add the employee to the leaderboard
	print("Adding Employee: Name = %s, ID = %s Scrap = %d, Gas = %s" % [EmployeeName, id, scrap, gas])

	# Clear the input fields after submission
	name_input.text = ""
	id_input.text = ""
	scrap_input.text = ""
	gas_input.text = ""


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/options.tscn")
