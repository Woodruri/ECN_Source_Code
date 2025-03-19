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

var current_report_id: String = ""
var point_inputs = {}

func reset_report_submission_status() -> void:
	# Load relationships data
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
	print("Starting dashboard initialization...")  # Debug print
	
	print("Loading all data...")  # Debug print
	DataHandler.load_all_data()  # Make sure data is loaded
	
	print("Resetting report submission status...")  # Debug print
	reset_report_submission_status()  # Reset submission status for testing
	
	print("Current user ID:", DataHandler.get_user_id())  # Debug print
	print("Employees data:", DataHandler.employees)  # Debug print
	print("Reports data:", DataHandler.reports)  # Debug print
	
	print("Updating user info...")  # Debug print
	update_user_info()
	
	print("Updating reports lists...")  # Debug print
	update_reports_lists()
	
	print("Dashboard initialization complete.")  # Debug print

func update_user_info() -> void:
	var user_data = DataHandler.get_user_data()
	print("User Data:", user_data)  # Debug print
	name_label.text = "Name: " + user_data.name
	points_label.text = "Earned Points: " + str(user_data.points)
	resources_label.text = "Resources: Gas: %s Scrap: %s" % [int(user_data.resources.gas), int(user_data.resources.scrap)]
	ranking_label.text = "Global Rank: #" + str(user_data.rank)

func update_reports_lists() -> void:
	print("Starting to update reports lists")  # Debug print
	
	# Clear existing items
	for child in active_reports_container.get_children():
		child.queue_free()
	inactive_reports_list.clear()
	
	var user_id = DataHandler.get_user_id()
	print("Current User ID:", user_id)  # Debug print
	
	var employee_data = DataHandler.get_employee_from_id(user_id)
	print("Employee Data:", employee_data)  # Debug print
	
	if not employee_data:
		print("No employee data found!")  # Debug print
		return
		
	print("Reports for employee:", employee_data.get("reports", []))  # Debug print
	
	# Load reports data
	DataHandler.load_import_data(DataHandler.reports, DataHandler.reports_path)
	
	for report_id in employee_data.get("reports", []):
		print("Processing report:", report_id)  # Debug print
		
		var relationship_key = DataHandler.get_relationship_key(user_id, report_id)
		print("Relationship key:", relationship_key)  # Debug print
		
		# Load relationships data to ensure we have the latest
		DataHandler.load_import_data(DataHandler.relationships, DataHandler.relationships_path)
		var relationship = DataHandler.relationships.get(relationship_key, {})
		var is_submitted = relationship.get("is_submitted", false)
		print("Is submitted:", is_submitted)  # Debug print
		
		var report_data = DataHandler.reports.get(report_id, {})
		var r2_count = report_data.get("r2_count", 0)
		var display_text = "%s [R2 Count: %d]" % [report_id, int(r2_count)]
		
		if not is_submitted:
			# Create a horizontal container for the report and button
			var hbox = HBoxContainer.new()
			hbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			
			# Add report label
			var label = Label.new()
			label.text = display_text
			label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			hbox.add_child(label)
			
			# Add allocate button
			var button = Button.new()
			button.text = "Allocate Points"
			button.pressed.connect(_on_allocate_button_pressed.bind(report_id))
			hbox.add_child(button)
			
			active_reports_container.add_child(hbox)
			print("Adding to active reports:", report_id)  # Debug print
		else:
			inactive_reports_list.add_item(display_text + " (Submitted)")
			print("Adding to inactive reports:", report_id)  # Debug print

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
	
	# Store the allocated points
	DataHandler.store_allocated_points(DataHandler.get_user_id(), current_report_id, points_dict)
	
	# Mark the report as submitted
	DataHandler.mark_report_as_submitted(DataHandler.get_user_id(), current_report_id)
	
	# Hide the popup
	allocation_popup.hide()
	
	# Update the reports lists
	update_reports_lists()

func _on_cancel_allocation_pressed() -> void:
	allocation_popup.hide()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/menu.tscn")
