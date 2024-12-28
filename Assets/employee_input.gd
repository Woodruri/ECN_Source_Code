extends VBoxContainer

# References to the input fields and button
@onready var name_input = $NameInput
@onready var points_input = $PointsInput
@onready var hat_input = $HatInput
@onready var submit_button = $SubmitButton

# Callback for the submit button
func _ready() -> void:
	print("Name Input:", name_input)
	print("Points Input:", points_input)
	print("Hat Input:", hat_input)
	submit_button.connect("pressed", _on_submit_button_pressed)

func _on_submit_button_pressed() -> void:
		# Get input values
	var EmployeeName = name_input.text.strip_edges()
	var points = int(points_input.text.strip_edges())
	var hat = hat_input.text.strip_edges()

	# Validate the inputs
	if EmployeeName == ""  or hat == "":
		print("All fields must be filled out!")
		return

	# Convert points to integer
	points = int(points)

	# Add the employee to the leaderboard
	print("Adding Employee: Name = %s, Points = %d, Hat = %s" % [EmployeeName, points, hat])
	get_parent().add_to_leaderboard(EmployeeName, points, hat)

	# Clear the input fields after submission
	name_input.text = ""
	points_input.text = ""
	hat_input.text = ""
