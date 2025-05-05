extends Control

@onready var name_label = $MarginContainer/VBoxContainer/UserInfoSection/NameLabel
@onready var points_label = $MarginContainer/VBoxContainer/UserInfoSection/PointsLabel
@onready var resources_label = $MarginContainer/VBoxContainer/UserInfoSection/ResourcesLabel
@onready var ranking_label = $MarginContainer/VBoxContainer/UserInfoSection/RankingLabel
@onready var active_reports_container = $MarginContainer/VBoxContainer/ReportsSection/ActiveReports/ReportsContainer
@onready var inactive_reports_list = $MarginContainer/VBoxContainer/ReportsSection/InactiveReports/ReportsList
@onready var allocation_popup = $AllocationPopup
@onready var allocation_points_container = $AllocationPopup/MarginContainer/VBoxContainer/PointsContainer
@onready var allocation_title = $AllocationPopup/MarginContainer/VBoxContainer/TitleLabel
@onready var report_details_popup = $ReportDetailsPopup
@onready var report_details_container = $ReportDetailsPopup/MarginContainer/VBoxContainer/DetailsContainer

# Profile selection UI elements
var profile_selection_popup: AcceptDialog
var profile_dropdown: OptionButton
var create_profile_button: Button
var profile_name_input: LineEdit
var user_id_input: LineEdit

var current_report_id: String = ""
var point_inputs = {}

# Constants for point calculation
const MAX_POINTS = 100  # Maximum points possible
const DECAY_RATE = 0.1  # Points decay per hour
const MIN_POINTS = 20   # Minimum points after decay

func reset_report_submission_status() -> void:
	# Load relationships data
	if DataHandler:
		DataHandler.load_import_data(DataHandler.relationships, DataHandler.relationships_path)
		
		var user_id = DataHandler.get_user_id()
		var employee_data = DataHandler.get_employee_from_id(user_id)
		
		if employee_data and "reports" in employee_data:
			for report_id in employee_data["reports"]:
				var relationship_key = DataHandler.get_relationship_key(user_id, report_id)
				if relationship_key in DataHandler.relationships:
					DataHandler.relationships[relationship_key]["is_submitted"] = false
		
		# Save the updated relationships
		DataHandler.save_dictionary_to_file(DataHandler.relationships, DataHandler.relationships_path)

func _ready() -> void:
	# Make sure DataHandler is available
	if not DataHandler:
		push_error("DataHandler singleton not found!")
		return
		
	# Load all data
	await DataHandler.load_all_data()
	
	# Connect the item selection signal
	inactive_reports_list.item_selected.connect(_on_report_selected)
	
	# Initialize the report details popup
	initialize_report_details_popup()
	
	# Check if user profile exists
	var user_id = DataHandler.get_user_id()
	var user_data = DataHandler.get_employee_from_id(user_id)
	
	print("Checking user data - ID: ", user_id, ", Data: ", user_data)
	
	if user_id.is_empty() or not user_data or user_data.is_empty() or user_data.get("name", "Unknown") == "Unknown":
		print("No valid user profile found, showing profile selection")
		# Create and show profile selection popup
		create_profile_selection_popup()
	else:
		print("Existing user profile found: ", user_data)
		# Update user info and reports
		update_user_info()
		update_reports_lists()

func initialize_report_details_popup() -> void:
	# Create the report details popup if it doesn't exist
	if not report_details_popup:
		report_details_popup = AcceptDialog.new()
		report_details_popup.title = "ECN Details"
		report_details_popup.dialog_text = ""
		report_details_popup.exclusive = true
		report_details_popup.unresizable = true
		report_details_popup.always_on_top = true
		report_details_popup.size = Vector2(500, 400)
		
		# Create a container for the details
		report_details_container = VBoxContainer.new()
		report_details_container.custom_minimum_size = Vector2(480, 350)
		report_details_container.add_theme_constant_override("separation", 10)
		report_details_popup.add_child(report_details_container)
		
		# Add a close button
		var close_button = Button.new()
		close_button.text = "Close"
		close_button.pressed.connect(_on_close_details_pressed)
		report_details_popup.add_child(close_button)
		
		# Add the popup to the scene
		add_child(report_details_popup)
		
		# Hide the popup initially
		report_details_popup.hide()

func create_profile_selection_popup() -> void:
	# Create the popup dialog
	profile_selection_popup = AcceptDialog.new()
	profile_selection_popup.title = "Select or Create Profile"
	profile_selection_popup.dialog_text = "Please select an existing profile or create a new one."
	profile_selection_popup.exclusive = true
	profile_selection_popup.unresizable = true
	profile_selection_popup.always_on_top = true
	
	# Create a container for the UI elements
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(300, 200)
	container.add_theme_constant_override("separation", 10)
	profile_selection_popup.add_child(container)
	
	# Create a label for the dropdown
	var dropdown_label = Label.new()
	dropdown_label.text = "Select Profile:"
	container.add_child(dropdown_label)
	
	# Create the dropdown
	profile_dropdown = OptionButton.new()
	profile_dropdown.custom_minimum_size = Vector2(280, 30)
	populate_profile_dropdown()
	container.add_child(profile_dropdown)
	
	# Create a separator
	var separator = HSeparator.new()
	container.add_child(separator)
	
	# Create a label for the new profile section
	var new_profile_label = Label.new()
	new_profile_label.text = "Create New Profile:"
	container.add_child(new_profile_label)
	
	# Create an input field for the new profile name
	profile_name_input = LineEdit.new()
	profile_name_input.placeholder_text = "Enter profile name"
	profile_name_input.custom_minimum_size = Vector2(280, 30)
	container.add_child(profile_name_input)
	
	# Create an input field for the user ID
	user_id_input = LineEdit.new()
	user_id_input.placeholder_text = "Enter user ID"
	user_id_input.custom_minimum_size = Vector2(280, 30)
	container.add_child(user_id_input)
	
	# Create a button to create a new profile
	create_profile_button = Button.new()
	create_profile_button.text = "Create Profile"
	create_profile_button.custom_minimum_size = Vector2(280, 30)
	create_profile_button.pressed.connect(_on_create_profile_pressed.bind(user_id_input))
	container.add_child(create_profile_button)
	
	# Connect the OK button to select the profile
	profile_selection_popup.confirmed.connect(_on_profile_selected)
	
	# Add the popup to the scene
	add_child(profile_selection_popup)
	
	# Show the popup
	profile_selection_popup.popup_centered()

func populate_profile_dropdown() -> void:
	# Clear existing items
	profile_dropdown.clear()
	
	# Add a default option
	profile_dropdown.add_item("Select a profile...", 0)
	
	# Get current user data
	var current_user_id = DataHandler.get_user_id()
	var current_user_data = DataHandler.get_employee_from_id(current_user_id)
	
	if current_user_data and not current_user_data.is_empty():
		var current_user_name = current_user_data.get("name", "Unknown")
		profile_dropdown.add_item(current_user_name, 1)
		profile_dropdown.set_item_metadata(1, current_user_id)
	
	# Add other players from game state
	var game_state = DataHandler.get_persistent_game_state()
	var other_players = game_state.get("other_players", {})
	var index = 2
	
	for player_id in other_players:
		var player_text = "Player (%s)" % player_id
		profile_dropdown.add_item(player_text, index)
		profile_dropdown.set_item_metadata(index, player_id)
		index += 1

func _on_create_profile_pressed(user_id_input: LineEdit) -> void:
	var profile_name = profile_name_input.text.strip_edges()
	var user_id = user_id_input.text.strip_edges()
	
	if profile_name.is_empty():
		OS.alert("Please enter a profile name", "Invalid Input")
		return
		
	if user_id.is_empty():
		OS.alert("Please enter a user ID", "Invalid Input")
		return
	
	# Create initial user data
	var initial_user_data = {
		"id": user_id,
		"name": profile_name,
		"points": 0,
		"rank": 1,
		"resources": {
			"gas": 0,
			"scrap": 0
		}
	}
	
	# Store the new profile
	DataHandler.store_employee(user_id, initial_user_data)
	
	# Set the user ID in DataHandler
	DataHandler.set_user_id(user_id)
	
	# Hide the popup
	profile_selection_popup.hide()
	
	# Update the UI immediately with local data
	update_user_info()
	update_reports_lists()
	
	# Try to sync with server in the background
	attempt_server_sync(user_id, initial_user_data)

func attempt_server_sync(user_id: String, user_data: Dictionary) -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_user_created.bind(http_request, user_id))
	
	var error = http_request.request(
		"http://localhost:8000/users/",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(user_data)
	)
	
	if error != OK:
		print("Failed to sync with server. Will retry later.")
		http_request.queue_free()

func _on_profile_selected() -> void:
	# Get the selected profile ID
	var selected_index = profile_dropdown.selected
	if selected_index <= 0:  # Default option or no selection
		return
		
	var employee_id = profile_dropdown.get_item_metadata(selected_index)
	var employee_data = DataHandler.get_employee_from_id(employee_id)
	
	if not employee_data:
		OS.alert("Failed to load profile data", "Error")
		return
	
	# Set the user ID in DataHandler
	DataHandler.set_user_id(employee_id)
	
	# Create initial user data from employee data
	var initial_user_data = {
		"id": employee_id,
		"name": employee_data.get("name", "Unknown"),
		"points": employee_data.get("points", 0),
		"rank": employee_data.get("rank", 1),
		"resources": employee_data.get("resources", {"gas": 0, "scrap": 0})
	}
	
	# Store the profile
	DataHandler.store_employee(employee_id, initial_user_data)
	
	# Hide the popup
	profile_selection_popup.hide()
	
	# Update the UI immediately with local data
	update_user_info()
	update_reports_lists()
	
	# Try to sync with server in the background
	attempt_server_sync(employee_id, initial_user_data)

func _on_user_created(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest, user_id: String) -> void:
	http_request.queue_free()
	
	if response_code != 201:  # 201 is the status code for successful creation
		OS.alert("Failed to create profile on server. Please try again.", "Error")
		return
	
	# Parse the response
	var json = JSON.parse_string(body.get_string_from_utf8())
	if not json:
		OS.alert("Failed to parse server response. Please try again.", "Error")
		return
	
	# Create the new profile data
	var user_data = {
		"id": user_id,
		"name": profile_name_input.text.strip_edges(),
		"points": 0,
		"rank": 1,
		"resources": {
			"gas": 0,
			"scrap": 0
		}
	}
	
	# Store the new profile
	DataHandler.store_employee(user_id, user_data)
	
	# Set the user ID in DataHandler
	DataHandler.set_user_id(user_id)
	
	# Load user data from server
	await load_user_data_from_server(user_id)
	
	# Update the dropdown
	populate_profile_dropdown()
	
	# Clear the input field
	profile_name_input.text = ""
	
	# Update the dashboard
	update_user_info()
	update_reports_lists()

func load_user_data_from_server(user_id: String) -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# Create a signal to wait for the response
	var response_received = false
	http_request.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		response_received = true
		_on_user_data_loaded(result, response_code, headers, body, http_request, user_id)
	)
	
	var error = http_request.request(
		"http://localhost:8000/users/" + user_id,
		[],
		HTTPClient.METHOD_GET
	)
	
	if error != OK:
		OS.alert("Failed to load user data from server. Please try again.", "Error")
		http_request.queue_free()
		return
	
	# Wait for the response
	while not response_received:
		await get_tree().create_timer(0.1).timeout

func _on_user_data_loaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest, user_id: String) -> void:
	http_request.queue_free()
	
	if response_code != 200:
		OS.alert("Failed to load user data from server. Please try again.", "Error")
		return
	
	# Parse the response
	var json = JSON.parse_string(body.get_string_from_utf8())
	if not json:
		OS.alert("Failed to parse server response. Please try again.", "Error")
		return
	
	# Update the user data in DataHandler
	var user_data = {
		"name": json.get("name", "Unknown"),
		"points": json.get("points", 0),
		"rank": json.get("rank", 1),
		"resources": json.get("resources", {"gas": 0, "scrap": 0})
	}
	
	DataHandler.employees[user_id] = user_data

func update_user_info() -> void:
	var user_id = DataHandler.get_user_id()
	var user_data = DataHandler.get_employee_from_id(user_id)
	
	# Check if user data was found
	if not user_data or user_data.get("name") == "Unknown":
		show_account_not_found_popup(user_id)
		return
	
	# Update UI with user data
	name_label.text = "Name: " + user_data.get("name", "Unknown")
	points_label.text = "Earned Points: " + str(user_data.get("points", 0))
	resources_label.text = "Resources: Gas: " + str(user_data.get("resources", {}).get("gas", 0)) + ", Scrap: " + str(user_data.get("resources", {}).get("scrap", 0))
	ranking_label.text = "Rank: " + str(user_data.get("rank", 1))

func calculate_potential_points(report_id: String, relationship_key: String) -> Dictionary:
	var report_data = DataHandler.reports.get(report_id, {})
	var relationship = DataHandler.relationships.get(relationship_key, {})
	
	# Get start and end dates
	var start_date = relationship.get("start_date", "")
	var end_date = relationship.get("end_date", "")
	
	# Calculate time taken in hours
	var hours_taken = 0
	if start_date != "" and end_date != "":
		var start = Time.get_unix_time_from_datetime_string(start_date)
		var end = Time.get_unix_time_from_datetime_string(end_date)
		hours_taken = (end - start) / 3600.0  # Convert seconds to hours
	
	# Calculate decay
	var decay = max(0.0, hours_taken * DECAY_RATE)
	
	# Calculate final points with decay
	var base_points = MAX_POINTS
	var decayed_points = max(MIN_POINTS, base_points - decay)
	
	return {
		"base": base_points,
		"decayed": decayed_points,
		"hours": hours_taken
	}

func get_actual_points(report_id: String, user_id: String) -> Dictionary:
	# Get the relationship key
	var relationship_key = DataHandler.get_relationship_key(user_id, report_id)
	
	# Get points allocated to this user
	var points_data = DataHandler.points_allocated.get(relationship_key, {})
	
	# Sum up all points allocated to this user
	var total_points = 0
	var decay_info = {
		"max_points": MAX_POINTS,
		"decayed_points": MAX_POINTS,
		"hours_taken": 0,
		"decay_rate": DECAY_RATE,
		"min_points": MIN_POINTS
	}
	
	# Get the first allocation data to get decay info
	if points_data.has("points"):
		decay_info = {
			"max_points": points_data.get("max_points", MAX_POINTS),
			"decayed_points": points_data.get("decayed_points", MAX_POINTS),
			"hours_taken": points_data.get("hours_taken", 0),
			"decay_rate": points_data.get("decay_rate", DECAY_RATE),
			"min_points": points_data.get("min_points", MIN_POINTS)
		}
		
		# Calculate actual points from the points dictionary
		var points_dict = points_data.get("points", {})
		if typeof(points_dict) == TYPE_DICTIONARY:
			for allocator_id in points_dict:
				var allocator_points = points_dict[allocator_id]
				if typeof(allocator_points) == TYPE_DICTIONARY and allocator_points.has(user_id):
					total_points += allocator_points[user_id]
	
	return {
		"points": total_points,
		"decay_info": decay_info
	}

func update_reports_lists() -> void:
	# Clear existing items
	for child in active_reports_container.get_children():
		child.queue_free()
	inactive_reports_list.clear()
	
	var user_id = DataHandler.get_user_id()
	var active_reports = DataHandler.get_active_ecns(user_id)
	var history = DataHandler.get_report_history(user_id)
	
	# Update active reports
	for report_id in active_reports:
		var report = DataHandler.reports.get(report_id)
		if report:
			# Create a container for this report
			var report_container = HBoxContainer.new()
			report_container.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			
			# Add report info
			var item = Label.new()
			item.text = "ECN: %s (R2 Count: %d)" % [report_id, report.get("r2_count", 0)]
			item.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			report_container.add_child(item)
			
			# Add submit button
			var submit_button = Button.new()
			submit_button.text = "Submit"
			submit_button.pressed.connect(_on_submit_report_pressed.bind(report_id))
			report_container.add_child(submit_button)
			
			active_reports_container.add_child(report_container)
	
	# Update inactive reports
	for report_data in history:
		if not active_reports.has(report_data["report_id"]):
			var report = DataHandler.reports.get(report_data["report_id"])
			if report:
				var points_info = ""
				if report_data.get("points_data"):
					points_info = " (Points: %d)" % report_data["points_data"].get("total_points", 0)
				
				var item_text = "ECN: %s%s" % [report_data["report_id"], points_info]
				var idx = inactive_reports_list.add_item(item_text)
				
				# Store the full report data as metadata
				inactive_reports_list.set_item_metadata(idx, report_data)

# Add this new function to handle report submission
func _on_submit_report_pressed(report_id: String) -> void:
	# Show the allocation popup for this report
	_on_allocate_button_pressed(report_id)

func _on_report_selected(index: int) -> void:
	# Clear existing details
	for child in report_details_container.get_children():
		child.queue_free()
	
	# Get the report data from metadata
	var report_data = inactive_reports_list.get_item_metadata(index)
	if not report_data:
		add_detail_label("Error: Report data not found")
		return
	
	var report_id = report_data.get("report_id", "Unknown")
	var relationship = report_data.get("relationship", {})
	var points_data = report_data.get("points_data", {})
	
	# Add report title
	add_detail_label("Report: " + report_id)
	add_detail_separator()
	
	# Add dates
	if relationship:
		add_detail_label("Start Date: " + relationship.get("start_date", "Unknown"))
		add_detail_label("End Date: " + relationship.get("end_date", "Unknown"))
		add_detail_separator()
	
	# Add points information
	if points_data:
		add_detail_label("Points Information:")
		add_detail_label("Time-based Points: " + str(points_data.get("time_points", 0)))
		add_detail_label("Peer Points: " + str(points_data.get("peer_points", 0)))
		add_detail_label("Total Points: " + str(points_data.get("total_points", 0)))
		add_detail_separator()
		
		# Add points breakdown from peers
		var points_breakdown = points_data.get("points_breakdown", {})
		if not points_breakdown.is_empty():
			add_detail_label("Points Received from Peers:")
			for peer_id in points_breakdown:
				var peer_data = DataHandler.get_employee_from_id(peer_id)
				var peer_name = peer_data.get("assignee_name", "Unknown") if peer_data else "Unknown"
				add_detail_label("  - " + peer_name + ": " + str(points_breakdown[peer_id]))
			add_detail_separator()
	
	# Add team members information
	var team_members = DataHandler.get_employees_from_ecn(report_id)
	if not team_members.is_empty():
		add_detail_label("Team Members:")
		for member_id in team_members:
			var member_data = DataHandler.get_employee_from_id(member_id)
			var member_name = member_data.get("assignee_name", "Unknown") if member_data else "Unknown"
			var member_status = "Submitted" if DataHandler.get_report_status(report_id) == "Completed" else "In Progress"
			add_detail_label("  - " + member_name + " (" + member_status + ")")
	
	# Show the popup
	report_details_popup.popup_centered()

func add_detail_label(text: String) -> void:
	var label = Label.new()
	label.text = text
	report_details_container.add_child(label)

func add_detail_separator() -> void:
	var separator = HSeparator.new()
	report_details_container.add_child(separator)

func _on_close_details_pressed() -> void:
	# Hide the popup using the proper Window method
	report_details_popup.hide()

func _on_allocate_button_pressed(report_id: String) -> void:
	current_report_id = report_id
	
	# Clear existing point inputs
	for child in allocation_points_container.get_children():
		child.queue_free()
	point_inputs.clear()
	
	# Set the title
	allocation_title.text = "Allocate Points for " + report_id
	
	# Get list of employees who worked on this report
	var employees = DataHandler.get_employees_from_ecn(report_id)
	var current_user_id = DataHandler.get_user_id()
	
	# Create input fields for each employee (except current user)
	for employee_id in employees:
		if employee_id == current_user_id:
			continue
			
		var employee_data = DataHandler.get_employee_from_id(employee_id)
		if not employee_data:
			continue
			
		var hbox = HBoxContainer.new()
		hbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		
		# Employee name label
		var label = Label.new()
		label.text = employee_data.get("assignee_name", "Unknown")
		label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		hbox.add_child(label)
		
		# Points input
		var spinbox = SpinBox.new()
		spinbox.min_value = 0
		spinbox.max_value = 100
		spinbox.step = 1
		point_inputs[employee_id] = spinbox
		hbox.add_child(spinbox)
		
		allocation_points_container.add_child(hbox)
	
	# Show the popup
	allocation_popup.popup_centered()

func _on_submit_points_pressed() -> void:
	var total_points = 0
	var points_dict = {}
	
	# Calculate total points and build points dictionary
	for employee_id in point_inputs:
		var points = point_inputs[employee_id].value
		total_points += points
		points_dict[employee_id] = points
	
	# Validate total points = 100
	if total_points != 100:
		OS.alert("Total points must equal 100", "Invalid Points")
		return
	
	# Calculate decayed points for this report
	var relationship_key = DataHandler.get_relationship_key(DataHandler.get_user_id(), current_report_id)
	var potential = calculate_potential_points(current_report_id, relationship_key)
	
	# Store the allocated points with decay information
	var allocation_data = {
		"points": points_dict,
		"max_points": potential.base,
		"decayed_points": potential.decayed,
		"hours_taken": potential.hours,
		"decay_rate": DECAY_RATE,
		"min_points": MIN_POINTS
	}
	
	# Store the allocation data
	DataHandler.store_allocated_points(DataHandler.get_user_id(), current_report_id, allocation_data)
	
	# Mark the report as submitted
	DataHandler.mark_report_as_submitted(DataHandler.get_user_id(), current_report_id)
	
	# Hide the popup
	allocation_popup.hide()
	
	# Update the reports lists
	update_reports_lists()

func _on_cancel_allocation_pressed() -> void:
	allocation_popup.hide()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn")

func show_account_not_found_popup(account_name: String):
	# Create a popup dialog
	var popup = AcceptDialog.new()
	popup.dialog_text = "Account: '%s' not found" % account_name
	popup.title = "Account Not Found"
	popup.exclusive = true
	popup.unresizable = true
	popup.always_on_top = true
	
	# Add the popup to the scene
	add_child(popup)
	
	# Show the popup
	popup.popup_centered(Vector2(300, 100))
	
	# Set a timer to automatically close the popup after 2 seconds
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func():
		popup.queue_free()
	)

func _on_load_data_button_pressed() -> void:
	var result = await DataHandler.export_all_data_to_file("user://data.json")
	if result != DataHandler.ErrorCode.SUCCESS:
		print("Error loading data: ", result)
		return
	print("Data loaded successfully")

func _on_save_data_button_pressed() -> void:
	var result = await DataHandler.import_all_data_from_file("user://data.json")
	if result != DataHandler.ErrorCode.SUCCESS:
		print("Error saving data: ", result)
		return
	print("Data saved successfully")
