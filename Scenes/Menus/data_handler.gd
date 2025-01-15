extends Node

@export var employees_path: String = "res://data/persistent_storage/employees.json"
@export var reports_path: String = "res://data/persistent_storage/reports.json"
@export var relationships_path: String = "res://data/persistent_storage/relationships.json"
@export var leaderboard_path: String = "res://data/persistent_storage/leaderboard.json"
@export var points_allocated_path: String = "res://data/persistent_storage/points_allocated.json"

#storage for employees and reports
var employees = {}
var reports = {}
var relationships = {}

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
				"r2_count": import_data["r2_count"],
				"employees" : [import_data["assignee_id"]],
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
		
		#checking if the given report does NOT have the employee in it's employees list

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
				"is_submitted" : false #represents if the employee has allocated points for the others who worked on this report
			}
			
		print("parsing complete")
		save_dictionary_to_file(employees, employees_path)
		save_dictionary_to_file(reports, reports_path)
		save_dictionary_to_file(relationships, relationships_path)
		
func get_relationship_key(employee_id: String, report_id: String):
	return employee_id + ":" + report_id
	
func save_dictionary_to_file(data_dictionary: Dictionary, file_path: String):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		print("Failed to save Dictionary: %s at filepath: %s", % data_dictionary, file)
		return

	var jstr = JSON.stringify(data_dictionary)
	file.store_line(jstr)

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

func load_all_data():
	print("Loading all data...")
	load_import_data(employees, employees_path)
	load_import_data(reports, reports_path)
	load_import_data(relationships, relationships_path)
	print("Data successfully loaded.")

func store_employee(name: String, ID: String):
	# Extremely inefficient way of handling this, 
	# it's kinda like going to the grocery store, filling your cart, and then only purchasing a single item every time that you want to buy something
	load_import_data(employees, employees_path)
	
	employees[ID] = {
		"assignee_name" : name,
		"assignee_id" : ID,
		#"personnel_number" : import_data["personnel_number"]
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

func calculate_leaderboard():
	#takes all of our employees, and makes an ordered list of all employees according to their scores
	pass

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

func reset_data():
	#used to wipe all the files, useful for debugging
	employees = {}
	reports = {}
	relationships = {}
	save_dictionary_to_file({}, employees_path)
	save_dictionary_to_file({}, reports_path)
	save_dictionary_to_file({}, relationships_path)
	save_dictionary_to_file({}, leaderboard_path)
	save_dictionary_to_file({}, points_allocated_path)
	

func load_leaderboard():
	pass

func get_employees_from_ecn(ecn_id: String):
	pass
