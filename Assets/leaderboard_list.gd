extends ItemList


# Called when the node enters the scene tree for the first time.
func load_data(data_path: String) -> void:
	#Clear items, prob not necessary but it's there
	clear()
	
	#Read path
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
					var points = parts[1].strip_edges()
					var hat = parts[2].strip_edges()
					
					#Add entry to item list
					print("Adding Employee: %s, Points: %s, Hat: %s" % [name, points, hat])
					add_item("%s | Points %s | Hat: %s" % [name, points, hat])
	else:
		print("Leaderboard data not found at: ", data_path)
