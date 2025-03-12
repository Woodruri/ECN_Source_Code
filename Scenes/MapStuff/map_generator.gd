extends Node2D

@export var map_config_location: String = "res://data/map/map.cfg"
@export var connection_line_color: Color = Color(0.5, 0.5, 0.5, 0.5)
@export var connection_line_width: float = 2.0

var map_data: Dictionary = {}

#This script handles generating the map that our players will load in from

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if map_config_location:
		map_data = load_map_data()
		draw_map(map_data)

func load_map_data() -> Dictionary:
	var config = ConfigFile.new()
	var err = config.load(map_config_location)
	
	if err != OK:
		print("Failed to load map config file")
		return {}
		
	var map_dict = {}
	
	# Read all sections (points) from config
	for point in config.get_sections():
		map_dict[point] = {
			"location": config.get_value(point, "location", Vector2.ZERO),
			"connections": config.get_value(point, "connections", [])
		}
	
	return map_dict

func draw_map(map_dict: Dictionary) -> void:
	# First draw all connections
	for point_name in map_dict:
		var point_data = map_dict[point_name]
		var start_pos = point_data["location"]
		
		# Draw lines to each connected point
		for connection in point_data["connections"]:
			if map_dict.has(connection):
				var end_pos = map_dict[connection]["location"]
				draw_connection_line(start_pos, end_pos)

func draw_connection_line(start: Vector2, end: Vector2) -> void:
	var line = Line2D.new()
	line.add_point(start)
	line.add_point(end)
	line.width = connection_line_width
	line.default_color = connection_line_color
	add_child(line)

# Optional: Add method to clear all drawn connections
func clear_map() -> void:
	for child in get_children():
		if child is Line2D:
			child.queue_free()
