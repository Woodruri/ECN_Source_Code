extends VBoxContainer

# References to the input fields and button
@onready var name_input = $NameInput
@onready var points_input = $PointsInput
@onready var hat_input = $HatInput
@onready var submit_button = $SubmitButton
@onready var id_input: LineEdit = $IDInput

# Callback for the submit button
func _ready() -> void:
	print("Name Input:", name_input)
	print("Points Input:", points_input)
	print("Hat Input:", hat_input)

func _on_submit_employee_button_pressed() -> void:
		# Get input values
	var EmployeeName = name_input.text.strip_edges()
	var points = int(points_input.text.strip_edges())
	var id = hat_input.text.strip_edges()
	var hat = id_input.text.strip_edges()

	# Validate the inputs
	if EmployeeName == ""  or id == "" or hat == "":
		print("All fields must be filled out!")
		return

	# Add the employee to the leaderboard
	print("Adding Employee: Name = %s, ID = %s Points = %d, Hat = %s" % [EmployeeName, points, hat])
	get_parent().add_to_leaderboard(EmployeeName, points, id, hat)

	# Clear the input fields after submission
	name_input.text = ""
	points_input.text = ""
	id_input.text = ""
	hat_input.text = ""
