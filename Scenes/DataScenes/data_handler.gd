extends Node

#This script covers almost all data I/O between the game and the backend

#information regarding data the uglier data persistence
@export var employees_path: String = "res://data/persistent_storage/employees.json"
@export var reports_path: String = "res://data/persistent_storage/reports.json"
@export var relationships_path: String = "res://data/persistent_storage/relationships.json"
@export var leaderboard_path: String = "res://data/persistent_storage/leaderboard.json"
@export var points_allocated_path: String = "res://data/persistent_storage/points_allocated.json"
@export var upgrades_path: String = "res://data/persistent_storage/upgrades.json"

#information that pertains traversal of the world map/resources
@export var materials_path: String = "res://data/persistent_storage/materials.json"
@export var rockets_path: String = "res://data/persistent_storage/rockets.json"
@export var rocket_positions_path: String = "res://data/persistent_storage/rocket_positions.json"


###################################################### DICTIONARIES ##################################################################


#dictionaries for memory access to this info
var employees: Dictionary = {}
'''
employee_id: 
			"assignee_name": Str
			"assignee_id": Str
'''
var reports: Dictionary = {}
'''
report_id: 
			"id": Str
			"RV_executor": Str
			"r2_count": int
			"employees": list of employee_ids
'''
var relationships: Dictionary = {}
'''
relationship_key:
			"employee_id": Str
			"report_id": Str
			"start_date": Str
			"end_date": Str
			"is_submitted": bool
'''
var points_allocated: Dictionary = {}
'''
'''

#traversal dicts
var materials: Dictionary = {}
'''
employee_id:
			"scrap": int
			"gas": int
'''
var rockets: Dictionary = {}
'''
employee_id:
			"planet_id": Str
'''
var rocket_positions: Dictionary = {}
'''
planet_id:
			"employees": list of employee_ids
'''

#Global user_id, this imitates if the user were to be logged in
var user_id: String = "lorum"

var upgrades: Dictionary = {}
'''
user_id:
	"gas_efficiency": float
	"point_multiplier": float
'''

var firebase_database = null

func _ready():
	if Engine.has_singleton("FirebaseDatabase"):
		firebase_database = Engine.get_singleton("FirebaseDatabase")

func set_user(new_user_id: String) -> void:
	user_id = new_user_id

####################################################### PARSING FUNCS #################################################################

#verifies selected file
func parse_data(file_path: String):
	print("Selected file to process: ", file_path)
	load_all_data()
	parse_csv(file_path)
	
func parse_csv(file_path: String):
	#opening csv file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open file: ", file)
		print("File error: ", FileAccess.get_open_error())
		return
		
	var csv_lines = file.get_as_text().split("\n")
	#going through each row
	for i in range(csv_lines.size()):
		#i == 0 skips header, lines[i].strip_edges() == "" skips empty lines
		if i == 0 or csv_lines[i].strip_edges() == "":
			continue
		
		var row = csv_lines[i].split(",")
		
		#dictionary containing our import data
		var import_data = {
			"report_id" : row[0].strip_edges(),
			"assignee_name" : row[1].strip_edges(),
			"assignee_id" : row[2].strip_edges(),
			"personnel_number" : row[3].strip_edges(),
			"organization_unit" : row[4].strip_edges(),
			"assignee_email" : row[5].strip_edges(),
			"RV_executor" : row[6].strip_edges(),
			"start_date" : row[7].strip_edges(),
			"end_date" : row[8].strip_edges(),
			"r2_count" : row[9].strip_edges()
		}
		
		# Add to reports if the report ID doesn't exist in that list
		if not reports.has(import_data["report_id"]):
			reports[import_data["report_id"]] = {
				"id": import_data["report_id"], 
				"RV_executor": import_data["RV_executor"],
				"r2_count": int(import_data["r2_count"]),
				"employees" : [import_data["assignee_id"]],
				"status": "In Progress"
				}
		else:
			pass #This should eventually update new information for a given report
		
		# Add to employees if the employees ID doesn't exist in that list
		if not employees.has(import_data["assignee_id"]):
			employees[import_data["assignee_id"]] = {
				"assignee_name" : import_data["assignee_name"],
				"assignee_id" : import_data["assignee_id"],
				"reports" : [import_data["report_id"]],
				#"personnel_number" : import_data["personnel_number"],
			}
		else:
			pass #This should update new information for a given employee as new info is updated
		
		# Add the employee to the report's employees list if not already present
		if reports.has(import_data["report_id"]):
			if "employees" in reports[import_data["report_id"]]:
				if not import_data["assignee_id"] in reports[import_data["report_id"]]["employees"]:
					reports[import_data["report_id"]]["employees"].append(import_data["assignee_id"])
			else:
				# Initialize the 'employees' list if it's missing
				reports[import_data["report_id"]]["employees"] = [import_data["assignee_id"]]
		else:
			print("Error: Report ID not found in reports: ", import_data["report_id"])

		# Add the report to the employee's reports list if not already present
		if employees.has(import_data["assignee_id"]):
			if "reports" in employees[import_data["assignee_id"]]:
				if not import_data["report_id"] in employees[import_data["assignee_id"]]["reports"]:
					employees[import_data["assignee_id"]]["reports"].append(import_data["report_id"])
			else:
				# Initialize the 'employees' list if it's missing
				reports[import_data["report_id"]]["employees"] = [import_data["assignee_id"]]
		else:
			print("Error: Report ID not found in reports: ", import_data["report_id"])
		
		# Add to relationships if the relationship ID doesn't exist in that list
		var relationship_key = get_relationship_key(import_data["assignee_id"], import_data["report_id"])
		if not relationships.has(relationship_key):
			relationships[relationship_key] = {
				"employee_id" : import_data["assignee_id"],
				"report_id" : import_data["report_id"],
				"start_date" : import_data["start_date"],
				"end_date" : import_data["end_date"],
				"is_submitted" : false  # Initialize as false for new relationships
			}
			
		print("parsing complete")
		save_dictionary_to_file(employees, employees_path)
		save_dictionary_to_file(reports, reports_path)
		save_dictionary_to_file(relationships, relationships_path)


################################################### STORAGE AND FILE MANIPULATION #####################################################################
	
#generic function to save any dictionary to its corresponding file, be wise with this function
func save_dictionary_to_file(data_dictionary: Dictionary, file_path: String):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		print("Failed to save Dictionary: %s at filepath: %s", % data_dictionary, file)
		return

	var jstr = JSON.stringify(data_dictionary)
	file.store_line(jstr)

#loads a file into a dictionary, be careful with this
func load_import_data(data_dictionary: Dictionary, file_path: String):
	#Loads existing data from file
	
	#check if file exists
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	#check for file existence
	if not file:
		print("No file found at: ", file_path)
		return
	
	
	#check if data exists in file 
	if not FileAccess.file_exists(file_path):
		print("No data found in file: ", file_path)
		return

	#Load data into provided dictionary
	#NOTE get_var can run arbitrary code, only allow data to be run here from trusted sources
	if not file.eof_reached():
		var curr_line = file.get_line().strip_edges()
		if curr_line:
			var parsed_line = JSON.parse_string(curr_line)
			for key in parsed_line.keys():
				#Add to dict only if key doenst already exist
				if not data_dictionary.has(key):
					data_dictionary[key] = parsed_line[key]
	print("Data loaded successfully from: ", file_path)

func print_data():
	print("reports:", reports)
	print("employees:", employees)
	print("relationships:", relationships)
	print("points allocated:", points_allocated)

func load_all_data():
	print("Loading all data...")
	load_import_data(employees, employees_path)
	load_import_data(reports, reports_path)
	load_import_data(relationships, relationships_path)
	print("Data successfully loaded.")

################################################ STORED OBJECTS ########################################################################

func store_employee(employee_name: String, ID: String):
	# Extremely inefficient way of handling this, 
	# it's kinda like going to the grocery store, filling your cart, and then only purchasing a single item every time that you want to buy something
	load_import_data(employees, employees_path)
	
	employees[ID] = {
		"assignee_name" : employee_name,
		"assignee_id" : ID,
	}
	
	save_dictionary_to_file(employees, employees_path)

func store_report(ID: String, executor: String, r2_count: int):
	load_import_data(reports, reports_path)
	
	reports[ID] = {
		"id": ID, 
		"RV_executor": executor,
		"r2_count": r2_count
		}
		
	save_dictionary_to_file(employees, employees_path)

#used to streamline getting the relationship key
func get_relationship_key(employee_id: String, report_id: String):
	return employee_id + ":" + report_id

func store_relationship(employee_id: String, report_id: String, start_date, close_date):
	load_import_data(relationships, relationships_path)
	
	var relationship_key = get_relationship_key(employee_id, report_id)
	
	relationships[relationship_key] = {
		"employee_id" : employee_id,
		"report_id" : report_id,
		"start_date" : start_date,
		"end_date" : close_date
	}
	
	save_dictionary_to_file(relationships, relationships_path)

func store_materials(employee_id: String, gas: int, scrap: int):
	#used to save an employee's materials
	load_import_data(materials, materials_path)
	materials[employee_id] = {
		"gas" : gas,
		"scrap" : scrap
	}
	save_dictionary_to_file(materials, materials_path)

func store_allocated_points(employee_id: String, report_id: String, points_dict: Dictionary):
	#used to save a point allocation event from the point allocation page
	#format is allocated_points[relationship_key] = {reciever_id1 : points given, reciever_id2 : points given, ...}
	load_import_data(points_allocated, points_allocated_path)
	var relationship_key = get_relationship_key(employee_id, report_id)
	points_allocated[relationship_key] = points_dict
	save_dictionary_to_file(points_allocated, points_allocated_path)

func reset_data():
	#used to wipe all the files, useful for debugging
	employees = {}
	reports = {}
	relationships = {}
	points_allocated = {}
	materials = {}
	save_dictionary_to_file({}, employees_path)
	save_dictionary_to_file({}, reports_path)
	save_dictionary_to_file({}, relationships_path)
	save_dictionary_to_file({}, leaderboard_path)
	save_dictionary_to_file({}, points_allocated_path)
	save_dictionary_to_file({}, materials_path)

################################################# RETRIEVAL #######################################################################

func calculate_employee_score(employee_id: String) -> int:
	var base_score = 0
	
	# Load reports data
	load_import_data(reports, reports_path)
	
	# Get points from reports
	for report_id in reports:
		var report = reports[report_id]
		if report.get("employees", []).has(employee_id):
			base_score += int(report.get("r2_count", 0)) * 10
	
	return base_score

func get_user_data() -> Dictionary:
	# Get the current user's data from employees
	var employee_data = get_employee_from_id(user_id)
	if not employee_data:
		return {}
	
	# Get user's materials from local storage
	load_import_data(materials, materials_path)
	var materials_data = materials.get(user_id, {"gas": 100, "scrap": 50})
	
	# Calculate user's points
	var points = calculate_employee_score(user_id)
	
	# Get user's rank from local leaderboard or generate fake entry
	var rank = 1  # Default to rank 1 for now
	
	# Get active ECNs
	var active_ecns = get_active_ecns(user_id)
	
	return {
		"name": employee_data.get("assignee_name", "Unknown"),
		"points": points,
		"resources": {
			"gas": materials_data.get("gas", 0),
			"scrap": materials_data.get("scrap", 0)
		},
		"rank": rank,
		"active_ecns": active_ecns,
		"upgrades": {
			"gas_efficiency": 0.0,
			"point_multiplier": 1.0
		}
	}

func get_user_id() -> String:
	return user_id

func get_user_materials(employee_id: String) -> Dictionary:
	if not firebase_database:
		return {}
		
	var path = "users/%s/materials" % employee_id
	var result = firebase_database.get_data(path)
	return result.get("data", {})

func get_rocket_data(employee_id: String) -> Dictionary:
	if not firebase_database:
		return {}
		
	var path = "users/%s/rocket" % employee_id
	var result = firebase_database.get_data(path)
	return result.get("data", {})

func get_rocket_position(employee_id: String):
	#takes emp_id and returns a string of the ID of the planet that the rocket belongs on
	load_import_data(rockets, rockets_path)
	if employee_id in rockets:
		return rockets[employee_id].get("planet_id", "Planet_1")
	return "Planet_1"  # Default to Planet_1 if no position found

func get_rockets_on_planet(planet_id: String) -> Array:
	if not firebase_database:
		return []
		
	var path = "planets/%s/rockets" % planet_id
	var result = firebase_database.get_data(path)
	return result.get("data", [])

func get_active_ecns(employee_id: String):
	#takes in a string that is the employee ID, and returns a list of ECN IDs for all ECNs that employee has active
	# returns [] if no ECNs are found
	
	#loading our stored data
	load_import_data(employees, employees_path)
	load_import_data(relationships, relationships_path)
	
	if employee_id not in employees:
		return []
	
	var employee_data = employees[employee_id]
	var ECN_list = []
	
	# gets a list of each incomplete report
	#employee_data["reports"] only gets the IDs
	for item in employee_data["reports"]:
		var relationship_key = get_relationship_key(employee_id, item)
		var curr_relationship = relationships[relationship_key]
		if curr_relationship["is_submitted"] == false:
			ECN_list.append(item)
	
	return ECN_list

func get_employees_from_ecn(ecn_id: String):
	#takes in a string that is the ecn ID, and returns a list of employee IDs that worked on that ECN
	# returns [] if no employees are found
	
	#loading our stored data
	load_import_data(reports, reports_path)
	
	if ecn_id not in reports:
		return []
	
	var report_data = reports[ecn_id]
	var emp_list = []
	
	# gets a list of each employee on a given ecn
	#report_data["employees"] only gets the IDs
	for item in report_data["employees"]:
		emp_list.append(item)
	
	return emp_list

func get_employee_from_id(employee_id: String):
	#pass in an employee id to get the employee object
	#horribly inefficient algorithm as this opens and closes the file for each employee, but memory is abundant and life is short
	
	load_import_data(employees, employees_path)
	if employees[employee_id]:
		return employees[employee_id]
	else:
		return false

############################################### LEADERBOARD STUFF #########################################################################

func calculate_leaderboard() -> Array:
	if not firebase_database:
		return []
		
	var path = "users"
	var users = firebase_database.get_data(path).get("data", {})
	var leaderboard_data = []
	
	for user_id in users:
		var user_data = users[user_id]
		var score = calculate_employee_score(user_id)
		leaderboard_data.append({
			"id": user_id,
			"name": user_data.get("display_name", "Unknown"),
			"points": score
		})
	
	leaderboard_data.sort_custom(func(a, b): return a["points"] > b["points"])
	
	# Store leaderboard
	firebase_database.set_data("leaderboard", leaderboard_data)
	return leaderboard_data

func generate_fake_leaderboard_entries(count: int) -> Array:
	var fake_entries = []
	for i in range(count):
		fake_entries.append({
			"rank": i + 1,
			"name": "Player_%d" % (i + 1),
			"points": randi() % 1000  # Random points between 0 and 999
		})
	return fake_entries

func get_leaderboard(quantity: int) -> Array:
	if not firebase_database:
		return []
		
	var path = "leaderboard"
	var result = firebase_database.get_data(path)
	var leaderboard_data = result.get("data", [])
	
	if leaderboard_data.is_empty():
		leaderboard_data = calculate_leaderboard()
	
	return leaderboard_data.slice(0, quantity)

func get_planet_leaderboard(planet: String, quantity: int) -> Array:
	if not firebase_database:
		return []
		
	var rockets = get_rockets_on_planet(planet)
	var full_leaderboard = get_leaderboard(999)
	
	var planet_leaderboard = []
	for entry in full_leaderboard:
		if entry["id"] in rockets:
			planet_leaderboard.append(entry)
	
	return planet_leaderboard.slice(0, quantity)

#TODO Be careful for doubled up ids

func get_user_upgrades(user_id: String) -> Dictionary:
	if not firebase_database:
		return {}
		
	var path = "users/%s/upgrades" % user_id
	var result = firebase_database.get_data(path)
	return result.get("data", {})

func store_upgrades(user_id: String, upgrade_data: Dictionary) -> void:
	if not firebase_database:
		return
		
	var path = "users/%s/upgrades" % user_id
	firebase_database.set_data(path, upgrade_data)

# Update the traverse cost calculation to use gas efficiency
func get_traverse_cost(planet_data: Dictionary) -> Dictionary:
	var user_id = get_user_id()
	var user_upgrades = get_user_upgrades(user_id)
	var efficiency = 1.0 - user_upgrades.get("gas_efficiency", 0.0)
	
	return {
		"gas": ceil(planet_data.resource_cost.gas * efficiency),
		"scrap": planet_data.resource_cost.scrap
	}

func store_rocket_position(employee_id: String, planet_id: String) -> void:
	if not firebase_database:
		return
		
	var path = "users/%s/rocket" % employee_id
	var data = {"planet_id": planet_id}
	firebase_database.set_data(path, data)
	
	# Update planet's rocket list
	var planet_path = "planets/%s/rockets" % planet_id
	var rockets = firebase_database.get_data(planet_path).get("data", [])
	if not employee_id in rockets:
		rockets.append(employee_id)
		firebase_database.set_data(planet_path, rockets)

func initialize_player_data(employee_id: String) -> void:
	# Initialize materials if not set
	if get_user_materials(employee_id).is_empty():
		store_materials(employee_id, 100, 50)
	
	# Initialize rocket position if not set
	if get_rocket_data(employee_id).is_empty():
		store_rocket_position(employee_id, "Planet_1")
	
	# Initialize upgrades if not set
	if get_user_upgrades(employee_id).is_empty():
		store_upgrades(employee_id, {
			"gas_efficiency": 0.0,
			"point_multiplier": 1.0
		})

func get_user_ecns() -> Array:
	'''
	Returns a list of dictionaries, each containing the title, status, and r2_count of an ECN,
	distinct from get_active_ecns() because this returns all ECNs that the user has worked on,
	regardless of whether they are currently active or not
	'''
	var user_id = get_user_id()
	var active_ecns = get_active_ecns(user_id)
	var ecn_list = []
	
	load_import_data(reports, reports_path)
	load_import_data(relationships, relationships_path)
	
	for ecn_id in active_ecns:
		if ecn_id in reports:
			var report = reports[ecn_id]
			var relationship_key = get_relationship_key(user_id, ecn_id)
			var is_submitted = relationships.get(relationship_key, {}).get("is_submitted", false)
			var status = "In Progress"
			if is_submitted:
				status = "Submitted"
			elif report.get("status") == "Completed":
				status = "Completed"
			
			var ecn_data = {
				"title": report["id"],
				"status": status,
				"r2_count": report["r2_count"]
			}
			ecn_list.append(ecn_data)
	
	return ecn_list

func mark_report_as_submitted(employee_id: String, report_id: String) -> void:
	# Load relationships data
	load_import_data(relationships, relationships_path)
	
	# Get the relationship key and update is_submitted
	var relationship_key = get_relationship_key(employee_id, report_id)	
	if relationships.has(relationship_key):
		relationships[relationship_key]["is_submitted"] = true
		save_dictionary_to_file(relationships, relationships_path)
		
		# Update report status if all employees have submitted
		var all_submitted = true
		var employees_list = get_employees_from_ecn(report_id)
		for emp_id in employees_list:
			var emp_relationship_key = get_relationship_key(emp_id, report_id)
			if relationships.has(emp_relationship_key) and not relationships[emp_relationship_key]["is_submitted"]:
				all_submitted = false
				break
		
		if all_submitted:
			load_import_data(reports, reports_path)
			if reports.has(report_id):
				reports[report_id]["status"] = "Completed"
				save_dictionary_to_file(reports, reports_path)

func get_report_status(report_id: String) -> String:
	load_import_data(reports, reports_path)
	if reports.has(report_id):
		return reports[report_id].get("status", "In Progress")
	return "Unknown"
