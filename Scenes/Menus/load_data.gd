extends Control


@onready var fd_load: FileDialog = $FileDialogLoad
@onready var file_selected: Label = $VBoxContainer/FileSelected
@onready var load_data_button: Button = $VBoxContainer/LoadDataButton

var selected_file_path:String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#set directory for fileDialog
	fd_load.current_dir = '/'


func _on_file_location_button_pressed() -> void:
	#create a file location popup and ask user to get the file we want it to use
	fd_load.visible = true


func _on_file_dialog_load_file_selected(path: String) -> void:
	#Called when a load file is selected from fd_load
	'''var load_file = FileAccess.open(path, FileAccess.READ)
	
	if not FileAccess.file_exists(path):
		print("file at: %s not found" % load_file)
		return
	
	print("File Selected: ", path)
	fd_load.current_file = path'''
	file_selected.text = "File path selected: %s" % path
	
		# Called when a file is selected from the FileDialog
	if not FileAccess.file_exists(path):
		print("File not found at: %s" % path)
		return

	selected_file_path = path  # Store the selected file path
	print("File Selected: ", selected_file_path)
	file_selected.text = "File path selected: %s" % selected_file_path


func _on_load_data_button_pressed() -> void:
	'''#calls the parser to load data in our data path
	print("attempting to load the file: ", fd_load.current_file)
	data_parser.parse_data(fd_load.current_file)'''
	
	# Calls the parser to load data from the selected file path
	if selected_file_path == "":
		print("No file selected to load.")
		return

	print("Attempting to load the file: ", selected_file_path)
	DataHandler.parse_data(selected_file_path)


func _on_print_data_button_pressed() -> void:
	DataHandler.print_data()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/options.tscn")


func _on_clear_data_button_pressed() -> void:
	DataHandler.reset_data()
