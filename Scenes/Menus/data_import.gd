extends Control

# UI References
@onready var import_file_dialog = $ImportFileDialog
@onready var update_file_dialog = $UpdateFileDialog
@onready var export_file_dialog = $ExportFileDialog
@onready var status_label = $VBoxContainer/StatusLabel
@onready var import_button = $VBoxContainer/ImportButton
@onready var update_button = $VBoxContainer/UpdateButton
@onready var export_button = $VBoxContainer/ExportButton
@onready var back_button = $VBoxContainer/BackButton

# File paths
var import_file_path = ""
var update_file_path = ""
var export_file_path = ""

func _ready():
	# Connect signals
	import_file_dialog.file_selected.connect(_on_import_file_selected)
	update_file_dialog.file_selected.connect(_on_update_file_selected)
	export_file_dialog.file_selected.connect(_on_export_file_selected)
	
	# Set initial status
	update_status("Ready to import or update data")

func update_status(message: String):
	status_label.text = message
	print(message)

func _on_import_button_pressed() -> void:
	var result = await DataHandler.import_all_data_from_file("user://data.json")
	if result != DataHandler.ErrorCode.SUCCESS:
		print("Error importing data: ", result)
		return
	print("Data imported successfully")

func _on_update_button_pressed():
	update_file_dialog.popup_centered()

func _on_export_button_pressed() -> void:
	var result = await DataHandler.export_all_data_to_file("user://data.json")
	if result != DataHandler.ErrorCode.SUCCESS:
		print("Error exporting data: ", result)
		return
	print("Data exported successfully")

func _on_import_file_selected(path: String):
	import_file_path = path
	update_status("Importing data from: " + path)
	
	# Import the data
	var result = await DataHandler.import_all_data_from_file(import_file_path)
	
	if result == DataHandler.ErrorCode.SUCCESS:
		update_status("Data imported successfully!")
	else:
		update_status("Error importing data: " + str(result))

func _on_update_file_selected(path: String):
	update_file_path = path
	update_status("Updating data from: " + path)
	
	# Update the data
	var result = await DataHandler.update_data_from_file(update_file_path)
	
	if result == DataHandler.ErrorCode.SUCCESS:
		update_status("Data updated successfully!")
	else:
		update_status("Error updating data: " + str(result))

func _on_export_file_selected(path: String):
	export_file_path = path
	update_status("Exporting data to: " + path)
	
	# Export the data
	var result = await DataHandler.export_all_data_to_file(export_file_path)
	
	if result == DataHandler.ErrorCode.SUCCESS:
		update_status("Data exported successfully!")
	else:
		update_status("Error exporting data: " + str(result))

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn") 