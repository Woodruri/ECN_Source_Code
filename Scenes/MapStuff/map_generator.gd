extends Node2D

@export var map_config_location: String = "res://data/map/map.cfg"

#This script handles generating the map that our players will load in from

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not map_config_location:
		var map_config = ConfigFile.new()
	

func load_map_data() -> void:
	#function that loads the config file that contains the map data into a dictionary
	pass

func draw_map(map_dict: Dictionary) -> void:
	#function that loads a map from a dictionary of the following format
	'''
	{"point_name": 
		{
			"location": vector2 (x,y)
			"connections" : array ["str of connection"]
		}	
	}
	'''
	pass
