extends Control

@onready var id_input: LineEdit = $VBoxContainer/IDInput
@onready var ecn_list: VBoxContainer = $VBoxContainer/ECNList

#consts
var MAX_VALUE = 100
var report_id = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_emp_id_button_pressed() -> void:
	#loads all active ECNs into the page
	var employee_id = id_input.text.strip_edges()
	DataHandler.set_user(employee_id)
	
	#get list of active ECNS and then creat a series of inputs for that list
	var active_ECN_list = DataHandler.get_active_ecns(employee_id)
	print("active_ecn_list: ", active_ECN_list)
	clear_ecn_list()
		
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
	#This is triggered when a generated ECN button is pressed, the ID is passed as argument
	
	#clear the list and then create a series of inputs for 
	clear_ecn_list()
	report_id = ECN_ID
	
	#Create label for the ECN ID
	var ECN_ID_label = Label.new()
	ECN_ID_label.text = "Selected ECN: " + ECN_ID
	ecn_list.add_child(ECN_ID_label)
	
	#add some instruction text
	var instruction_text = Label.new()
	instruction_text.text = "Make sure that all points summed up are are <= 100 points and >= 0. 
	For now, just don't give yourself points (or do, go crazy with it, nothing is real yet)"
	ecn_list.add_child(instruction_text)
	
	#Get list of employees on ecn
	var employee_ID_list = DataHandler.get_employees_from_ecn(ECN_ID)
	
	#clear the list if an empty array is returned
	if employee_ID_list == []:
		_clear_list_button_pressed()
	
	#Create label and input field for each employee on ECN, hook them up to another trigger
	for employee_id in employee_ID_list:
		#load employee object to access its other data
		var employee = DataHandler.get_employee_from_id(employee_id)
		var HBox = HBoxContainer.new()
		var nameLabel = Label.new()
		var input = LineEdit.new()
		HBox.name = employee_id
		nameLabel.name = "label" + employee_id
		nameLabel.text = employee["assignee_name"]
		input.name = "input" + employee_id
		HBox.add_child(nameLabel)
		HBox.add_child(input)
		ecn_list.add_child(HBox)
	
	#add a submit points button
	var submit_points_button = Button.new()
	submit_points_button.text = "Submit Points"
	submit_points_button.name = "submit_points_button"
	submit_points_button.pressed.connect(_submit_points_button_pressed.bind())
	ecn_list.add_child(submit_points_button)

func _submit_points_button_pressed():
	#triggers when the employee wants to submit their points for another employee, point validation is handled here
	
	var sum = 0
	var data = {}
	var employee_id = ""
	
	#get the sum of points being submitted and match them to the IDs
	for box in ecn_list.get_children():
		if not box is HBoxContainer:
			continue
		employee_id = box.name
		var value = 0
		
		#pos 0 is the label, 1 is the lineEdit
		if box.get_child(1):
			value = int(box.get_child(1).text.strip_edges())
		sum += value
		data[employee_id] = value
	
	if sum > MAX_VALUE:
		print("%d > %d, this is not allowed" % [sum, MAX_VALUE])
	elif sum <= 0:
		print("%d < 0, this is not allowed" % sum)
	else:
		print("Successfully submitted points: ", data)
	DataHandler.store_allocated_points(DataHandler.get_user_id(), report_id, data)

func _clear_list_button_pressed():
	#Just used to clear the list
	clear_ecn_list()

func clear_ecn_list():
	for child in ecn_list.get_children():
		ecn_list.remove_child(child)
		child.queue_free()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn")
