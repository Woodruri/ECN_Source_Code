extends Camera2D

#zoom params
var zoom_target = Vector2(1,1)
var zoom_speed = 5.0

#panning params
var is_dragging = false
var drag_start_pos = Vector2()
var camera_start_pos = Vector2()

#locking mechanism
var is_locked = false
var locked_position = Vector2()

func _ready():
	# Connect to the tree to detect when focus is lost
	get_tree().root.connect("gui_focus_changed", _on_focus_changed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#smooth zoom
	zoom = zoom.lerp(zoom_target, delta * zoom_speed)
	
	#if locked, smoothly move to locked pos
	if is_locked:
		global_position = global_position.lerp(locked_position, delta * zoom_speed)
	
	# Force check mouse button state
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		is_dragging = false

func _input(event):
	# If locked, don't process drag inputs
	if is_locked:
		is_dragging = false
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not get_tree().get_root().gui_is_dragging():
			is_dragging = true
			drag_start_pos = get_global_mouse_position()
			camera_start_pos = global_position
		else:
			is_dragging = false
			
	elif event is InputEventMouseMotion and is_dragging:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var drag_delta = get_global_mouse_position() - drag_start_pos
			global_position = global_position.lerp(camera_start_pos - drag_delta, 0.2)
		else:
			is_dragging = false

func _notification(what):
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		is_dragging = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		is_dragging = false

func _on_focus_changed(_control):
	is_dragging = false

#External call to lock camera (for when leaderboard pops up)
func lock_to_position(given_position, target_zoom):
	is_locked = true
	is_dragging = false  # Force reset dragging state
	locked_position = given_position
	zoom_target = target_zoom

#External call to unlock the camera
func unlock_camera():
	is_locked = false
	is_dragging = false  # Force reset dragging state
	zoom_target = Vector2(1,1) #reset to default zoom level
