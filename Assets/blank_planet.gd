extends Area2D

#original values before we modify them
var original_scale = scale
var original_modulate = modulate

#gets our leaderboard child node for easy future use
@onready var leaderboard = $Leaderboard
@onready var closeButton = $Leaderboard/MarginContainer/VBoxContainer/CloseButton
@onready var leaderboardList = $Leaderboard/MarginContainer/VBoxContainer/LeaderboardList

#gets the camera node
@onready var camera = get_node("/root/Game/Camera")

var leaderboard_data = []

func _ready() -> void:
	leaderboard.visible = false
	var data_path = "res://data/data.txt"
	load_leaderboard(data_path)
	closeButton.connect("pressed", close_menu)

#These two functions handle hovering over the planet to provide feedback that it is clickable
func _on_mouse_entered() -> void:
	scale = scale * 1.05 #Scale up slightly to add feedback
	modulate = Color(1, 1, 0.85, 1)  # Add yellow-ish color 
func _on_mouse_exited() -> void:
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
	leaderboard.visible = true

	# Lock camera to fit the planet and leaderboard
	var leaderboard_offset = Vector2(250, 0)  # Distance to place the leaderboard relative to the planet
	var camera_target = global_position + leaderboard_offset / 2  # Position between the planet and leaderboard
	var zoom_level = Vector2(2.5, 2.5)  # Adjust zoom level to fit both elements
	camera.lock_to_position(camera_target, zoom_level)

#closes the leaderboard after the close button is pressed
func close_menu():
	leaderboard.visible = false
	camera.unlock_camera()


#Leaderboard specific functions

func add_to_leaderboard(EmployeeName, points, hat):
	leaderboard_data.append({ "name": EmployeeName, "points": points, "hat": hat })
	sort_leaderboard()
	

#populates leaderboard with data
func load_leaderboard(data_path):

		
	#read data file#Read path
	if FileAccess.file_exists(data_path):
		var file = FileAccess.open(data_path, FileAccess.READ)
		var lines = file.get_as_text().strip_edges().split("\n")
		file.close()
	
		#process each line
		
		for line in lines:
			if line.strip_edges() != "":
				var parts = line.split(",")
				if parts.size() >= 3:
					var EmployeeName = parts[0].strip_edges()
					var points = int(parts[1].strip_edges())
					var hat = parts[2].strip_edges()
					leaderboard_data.append({ "name": EmployeeName, "points": points, "hat": hat })
	sort_leaderboard()

func sort_leaderboard():
	#clear existing list items
	leaderboardList.clear()
	
# Sort the data by points in descending order
	leaderboard_data.sort_custom(func(a, b):
		return b["points"] < a["points"]
		)

	# Populate the leaderboard with rankings
	var rank = 1
	for entry in leaderboard_data:
		leaderboardList.add_item(
			"%d. %s | Points: %d | Hat: %s" % [rank, entry["name"], entry["points"], entry["hat"]]
		)
		rank += 1
