extends Control

@onready var id_input: LineEdit = $VBoxContainer/IDInput
@onready var data_handler: Node = $DataHandler
@onready var ecn_list: VBoxContainer = $VBoxContainer/ECNList

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_emp_id_button_pressed() -> void:
	#loads all active ECNs into the page
	var employee_id = id_input.text.strip_edges()
	
	#get list of active ECNS and then creat a series of inputs for that list
	var active_ECN_list = data_handler.get_active_ecns(employee_id)
	print("active_ecn_list: ", active_ECN_list)
	for child in ecn_list.get_children():
		ecn_list.remove_child(child)
		child.queue_free()
		
	for ECN_ID in active_ECN_list:
		var button = Button.new()
		button.text = ECN_ID
		button.name = ECN_ID
		button.pressed.connect(_ECN_button_pressed.bind(ECN_ID))
		ecn_list.add_child(button)
	var clear_list_button = Button.new()
	clear_list_button.text = "Clear List"
	clear_list_button.name = "ClearListButton"
	clear_list_button.pressed.connect(_clear_list_button_pressed)
	ecn_list.add_child(clear_list_button)
	

func _ECN_button_pressed(ECN_ID):
	pass

func _clear_list_button_pressed():
	pass

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn")
