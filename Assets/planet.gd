extends Area2D

"""#original values before we modify them
var original_scale = Vector2()
var original_modulate = Color()

#gets our child nodes in vars for easy future use
@onready var leaderboard = $Leaderboard
@onready var leaderboardList = $Leaderboard/MarginContainer/VBoxContainer/LeaderboardList
@onready var closeButton = $Leaderboard/MarginContainer/VBoxContainer/CloseButton

#Dynamically set camera in main game scene
@onready var camera = null
func set_camera(camera_ref):
	camera = camera_ref

#set leaderboard and children to invisible by default
func _ready() -> void:
	
	
	leaderboard.visible = false
	original_modulate = modulate
	original_scale = scale
	
	#connect closed button to close_menu func
	closeButton.pressed.connect(close_menu)

#These two functions handle hovering over the planet to provide feedback that it is clickable
func _on_mouse_entered() -> void:
	print("Mouse entered")
	scale = scale * 1.05 #Scale up slightly to add feedback
	modulate = Color(1, 1, 0.85, 1)  # Add yellow-ish color 

func _on_mouse_exited() -> void:
	print("Mouse exited")
	scale = original_scale
	modulate = Color(1, 1, 1, 1)  # Restore original color.

#handles all other input events
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	#handles when the planet is clicked 
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("planet clicked")
		open_menu()

#opens the leaderboard after being clicked on
func open_menu():
	# Show the leaderboard UI
	var data_path = "res://data/data.txt"
	load_leaderboard(data_path)
	
	# Lock camera to fit the planet and leaderboard
	var leaderboard_offset = Vector2(250, 0)  # Distance to place the leaderboard relative to the planet
	var camera_target = global_position + leaderboard_offset / 2  # Position between the planet and leaderboard
	var zoom_level = Vector2(2.5, 2.5)  # Adjust zoom level to fit both elements
	camera.lock_to_position(camera_target, zoom_level)

#closes the leaderboard after the close button is pressed
func close_menu():
	leaderboard.visible = false
	if camera:
		camera.unlock_camera()
	else:
		print("No camera set for planet")


#Leaderboard specific functions

#opens the leaderboard and populates it with data
func load_leaderboard(data_path):
	leaderboard.visible = true
	if FileAccess.file_exists(data_path):
		leaderboardList.load_data(data_path)
	else:
		print("Data file not found at: %s" % data_path)


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	pass # Replace with function body.
"""
