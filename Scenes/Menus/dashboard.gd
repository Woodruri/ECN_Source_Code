extends Control

@onready var name_label = $MarginContainer/VBoxContainer/UserInfoSection/NameLabel
@onready var points_label = $MarginContainer/VBoxContainer/UserInfoSection/PointsLabel
@onready var resources_label = $MarginContainer/VBoxContainer/UserInfoSection/ResourcesLabel
@onready var ranking_label = $MarginContainer/VBoxContainer/UserInfoSection/RankingLabel
@onready var active_reports_list = $MarginContainer/VBoxContainer/ReportsSection/ActiveReports/ReportsList
@onready var inactive_reports_list = $MarginContainer/VBoxContainer/ReportsSection/InactiveReports/ReportsList

func _ready() -> void:
	# Verify UI nodes are properly connected
	print("Active Reports List node exists:", active_reports_list != null)
	print("Inactive Reports List node exists:", inactive_reports_list != null)
	
	DataHandler.load_all_data()  # Make sure data is loaded
	update_user_info()
	update_reports_lists()

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
	if active_reports_list and active_reports_list.get_child_count() > 0:
		for child in active_reports_list.get_children():
			child.queue_free()
	
	if inactive_reports_list and inactive_reports_list.get_child_count() > 0:
		for child in inactive_reports_list.get_children():
			child.queue_free()
	
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
		
		var hbox = HBoxContainer.new()
		hbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)  # Make HBox expand horizontally
		
		# Create report info label
		var label = Label.new()
		var report_data = DataHandler.reports.get(report_id, {})
		var r2_count = report_data.get("r2_count", 0)
		label.text = "%s [R2 Count: %d]" % [report_id, r2_count]
		label.set_h_size_flags(Control.SIZE_EXPAND_FILL)  # Make label expand
		hbox.add_child(label)
		
		if not is_submitted:
			var button = Button.new()
			button.text = "Allocate Points"
			button.pressed.connect(_on_allocate_button_pressed.bind(report_id))
			hbox.add_child(button)
			print("Adding to active reports:", report_id)  # Debug print
			if active_reports_list:
				active_reports_list.add_child(hbox)
		else:
			var status = Label.new()
			status.text = "Submitted"
			hbox.add_child(status)
			print("Adding to inactive reports:", report_id)  # Debug print
			if inactive_reports_list:
				inactive_reports_list.add_child(hbox)

func _on_allocate_button_pressed(report_id: String) -> void:
	# Store the selected report ID in the DataHandler
	DataHandler.selected_report_id = report_id
	# Change to the allocate points scene
	get_tree().change_scene_to_file("res://Scenes/Menus/allocate_points.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/menu.tscn")
