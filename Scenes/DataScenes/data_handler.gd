extends Node

# Constants
var SERVER_URL = "http://localhost:8000"  # Can be changed in _ready()
const API_VERSION = "v1"

# User data
var current_user_id: String = ""

# Local player data (stored persistently)
var local_player_data: Dictionary = {
	"id": "",
	"name": "",
	"points": 0,
	"rank": 1,
	"resources": {
		"gas": 0,
		"scrap": 0
	}
}

# Game state (stored persistently)
var game_state: Dictionary = {
	"current_planet": "Planet_1",
	"other_players": {}  # Only stores other players' positions: {player_id: planet_id}
}

# Temporary data (not stored)
var cosmetics: Dictionary = {}
var shop_items: Dictionary = {}
var ecns: Array = []

# Local data storage
var reports: Dictionary = {}
var relationships: Dictionary = {}
var points_allocated: Dictionary = {}
var relationships_path: String = "user://relationships.json"
var player_data_path: String = "user://player_data.json"  # Path for local player data
var game_state_path: String = "user://game_state.json"    # Path for game state

# Static instance
static var instance: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("DataHandler initializing...")
	
	# Set the static instance
	instance = self
	
	# Check for command line argument for server URL
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg.begins_with("--server="):
			SERVER_URL = arg.split("=")[1]
			print("Using server URL: ", SERVER_URL)
			break
	
	print("DataHandler initialized with server URL: ", SERVER_URL)
	
	# Load local data
	load_local_data()
	
	# Test server connection
	test_server_connection()

# Local Data Management
func load_local_data() -> void:
	print("Loading local data...")
	
	# Load player data
	var player_file = FileAccess.open(player_data_path, FileAccess.READ)
	if player_file:
		var json = JSON.parse_string(player_file.get_as_text())
		if json:
			local_player_data = json
			current_user_id = json.get("id", "")
			print("Loaded local player data")
		player_file.close()
	
	# Load game state
	var game_state_file = FileAccess.open(game_state_path, FileAccess.READ)
	if game_state_file:
		var json = JSON.parse_string(game_state_file.get_as_text())
		if json:
			game_state = json
			print("Loaded game state")
		game_state_file.close()

func save_local_data() -> void:
	print("Saving local data...")
	
	# Save player data
	var player_file = FileAccess.open(player_data_path, FileAccess.WRITE)
	if player_file:
		player_file.store_string(JSON.stringify(local_player_data))
		player_file.close()
		print("Saved local player data")
	
	# Save game state
	var game_state_file = FileAccess.open(game_state_path, FileAccess.WRITE)
	if game_state_file:
		game_state_file.store_string(JSON.stringify(game_state))
		game_state_file.close()
		print("Saved game state")

# Player Management
func initialize_player_data(user_id: String) -> void:
	print("Initializing player data for: ", user_id)
	
	# Check if we already have local data
	if current_user_id == user_id and not local_player_data.is_empty():
		print("Using existing local player data")
		return
	
	# Create new player data
	local_player_data = {
		"id": user_id,
		"name": "Player",
		"points": 0,
		"rank": 1,
		"resources": {
			"gas": 0,
			"scrap": 0
		}
	}
	current_user_id = user_id
	
	# Save locally
	save_local_data()
	
	# Try to sync with server
	attempt_player_data_sync()

func attempt_player_data_sync() -> void:
	print("Attempting to sync with server...")
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		print("Server sync response:")
		print("- Result: ", result)
		print("- Response code: ", response_code)
		
		if response_code == 201:  # Created
			print("Player data successfully synced with server")
		else:
			print("Warning: Failed to sync with server, will retry later")
		
		http_request.queue_free()
	)
	
	var error = http_request.request(
		"%s/api/%s/users" % [SERVER_URL, API_VERSION],
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(local_player_data)
	)
	
	if error != OK:
		print("Error making server sync request: ", error)
		http_request.queue_free()

# Game State Management
func get_rocket_data(user_id: String) -> Dictionary:
	# For local player, return full data
	if user_id == current_user_id:
		return {
			"planet_id": game_state.get("current_planet", "Planet_1"),
			"player_data": local_player_data
		}
	
	# For other players, only return position
	return {
		"planet_id": game_state.get("other_players", {}).get(user_id, "Planet_1")
	}

func get_rockets_on_planet(planet_id: String) -> Array:
	var rockets = []
	
	# Add local player if on this planet
	if game_state.get("current_planet") == planet_id:
		rockets.append(current_user_id)
	
	# Add other players on this planet
	for player_id in game_state.get("other_players", {}):
		if game_state.get("other_players", {}).get(player_id) == planet_id:
			rockets.append(player_id)
	
	return rockets

func store_rocket_position(user_id: String, planet_id: String) -> void:
	if user_id == current_user_id:
		game_state["current_planet"] = planet_id
	else:
		if not game_state.has("other_players"):
			game_state["other_players"] = {}
		game_state["other_players"][user_id] = planet_id
	
	save_local_data()
	
	# Sync with server
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		if response_code != 200:
			print("Error syncing rocket position: HTTP ", response_code)
		http_request.queue_free()
	)
	
	var error = http_request.request(
		"%s/api/%s/users/%s/game_state" % [SERVER_URL, API_VERSION, user_id],
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify({
			"current_planet": planet_id,
			"current_level": game_state.get("current_level", 1),
			"score": game_state.get("score", 0)
		})
	)
	
	if error != OK:
		print("Error making rocket position request: ", error)
		http_request.queue_free()

# Resource Management
func get_user_materials(user_id: String) -> Dictionary:
	if user_id == current_user_id:
		return local_player_data.get("resources", {"gas": 0, "scrap": 0})
	return {"gas": 0, "scrap": 0}  # Other players' resources not stored locally

func store_materials(user_id: String, gas: int, scrap: int) -> void:
	if user_id == current_user_id:
		local_player_data["resources"] = {
			"gas": gas,
			"scrap": scrap
		}
		save_local_data()
		
		# Sync with server
		var http_request = HTTPRequest.new()
		add_child(http_request)
		
		http_request.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
			http_request.queue_free()
		)
		
		var error = http_request.request(
			"%s/api/%s/users/%s/resources" % [SERVER_URL, API_VERSION, user_id],
			["Content-Type: application/json"],
			HTTPClient.METHOD_POST,
			JSON.stringify({
				"gas": gas,
				"scrap": scrap
			})
		)
		
		if error != OK:
			print("Error syncing resources: ", error)
			http_request.queue_free()

func test_server_connection() -> void:
	print("Testing server connection...")
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# Connect the signal before making the request
	http_request.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		print("Server connection test response:")
		print("- Result: ", result)
		print("- Response code: ", response_code)
		print("- Headers: ", headers)
		print("- Body: ", body.get_string_from_utf8())
		http_request.queue_free()
	)
	
	var error = http_request.request(SERVER_URL, [], HTTPClient.METHOD_GET)
	if error != OK:
		print("Error testing server connection: ", error)
		http_request.queue_free()

# Static method to get the instance
static func get_instance() -> Node:
	if instance == null:
		print("Error: DataHandler instance not found!")
		return null
	return instance

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Helper function to make HTTP requests
func make_request(endpoint: String, method: HTTPClient.Method, data: Dictionary = {}) -> Dictionary:
	print("Making request to: ", SERVER_URL, "/api/", API_VERSION, "/", endpoint)
	print("Method: ", method)
	print("Data: ", data)
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var url = "%s/api/%s/%s" % [SERVER_URL, API_VERSION, endpoint]
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(data) if not data.is_empty() else ""
	
	print("Full URL: ", url)
	print("Headers: ", headers)
	print("Body: ", body)
	
	var error = http_request.request(url, headers, method, body)
	if error != OK:
		print("Error making request: ", error)
		http_request.queue_free()
		return {}
	
	# Wait for the request to complete
	var result = await http_request.request_completed
	
	# Remove the HTTPRequest node
	http_request.queue_free()
	
	# Parse the response
	var response = result[0]
	var response_code = result[1]
	var response_headers = result[2]
	var response_body = result[3]
	
	print("Response code: ", response_code)
	print("Response headers: ", response_headers)
	print("Response body: ", response_body.get_string_from_utf8())
	
	if response_code != 200:
		print("Error: HTTP request failed with code ", response_code)
		return {}
	
	var json = JSON.parse_string(response_body.get_string_from_utf8())
	if json == null:
		print("Error: Invalid JSON response")
		return {}
		
	return json

# User Management
func get_user_id() -> String:
	return current_user_id

func set_user_id(user_id: String) -> void:
	current_user_id = user_id

# Cosmetic Management
func get_user_cosmetics(user_id: String) -> Dictionary:
	var response = await make_request("users/%s/cosmetics" % user_id, HTTPClient.METHOD_GET)
	cosmetics = response
	return response

func update_user_cosmetics(user_id: String, cosmetics_data: Dictionary) -> void:
	await make_request("users/%s/cosmetics" % user_id, HTTPClient.METHOD_PUT, cosmetics_data)
	cosmetics = await get_user_cosmetics(user_id)

# Shop Management
func get_shop_items() -> Dictionary:
	var response = await make_request("shop/items", HTTPClient.METHOD_GET)
	shop_items = response
	return response

func purchase_item(user_id: String, item_id: String) -> void:
	await make_request("shop/purchase", HTTPClient.METHOD_POST, {
		"user_id": user_id,
		"item_id": item_id
	})

# Leaderboard Management
func get_global_leaderboard(limit: int = 10) -> Array:
	var response = await make_request("leaderboard/global?limit=%d" % limit, HTTPClient.METHOD_GET)
	return response.get("entries", [])

func get_planet_leaderboard(planet_id: String, limit: int = 10) -> Array:
	var response = await make_request("leaderboard/planet/%s?limit=%d" % [planet_id, limit], HTTPClient.METHOD_GET)
	return response.get("entries", [])

# ECN Management
func get_user_ecns(user_id: String) -> Array:
	var response = await make_request("users/%s/ecns" % user_id, HTTPClient.METHOD_GET)
	ecns = response.get("ecns", [])
	return ecns

func submit_ecn(user_id: String, ecn_id: String) -> void:
	await make_request("ecns/submit", HTTPClient.METHOD_POST, {
		"user_id": user_id,
		"ecn_id": ecn_id
	})

# Employee Management
func get_employee_from_id(employee_id: String) -> Dictionary:
	# For local player, return full data
	if employee_id == current_user_id:
		return local_player_data
	
	# For other players, only return position
	return {
		"id": employee_id,
		"current_planet": game_state.get("other_players", {}).get(employee_id, "Planet_1")
	}

func get_employee_name(employee_id: String) -> String:
	if employee_id == current_user_id:
		return local_player_data.get("name", "Player")
	return "Player"  # Other players' names not stored locally

func get_employee_points(employee_id: String) -> int:
	if employee_id == current_user_id:
		return local_player_data.get("points", 0)
	return 0  # Other players' points not stored locally

func get_employee_rank(employee_id: String) -> int:
	if employee_id == current_user_id:
		return local_player_data.get("rank", 1)
	return 1  # Other players' ranks not stored locally

func store_employee(employee_id: String, employee_data: Dictionary) -> void:
	print("Storing employee data for: ", employee_id)
	
	# Only store local player's full data
	if employee_id == current_user_id:
		local_player_data = employee_data
		save_local_data()
		attempt_player_data_sync()
	else:
		# For other players, only store their position if they're on a planet
		if employee_data.has("current_planet"):
			if not game_state.has("other_players"):
				game_state["other_players"] = {}
			game_state["other_players"][employee_id] = employee_data["current_planet"]
			save_local_data()

# Report Management
func get_active_ecns(user_id: String) -> Array:
	var active_reports = []
	for report_id in reports:
		var report = reports[report_id]
		if report and report.get("status") == "Active":
			active_reports.append(report_id)
	return active_reports

func get_report_history(user_id: String) -> Array:
	var history = []
	for report_id in reports:
		var report = reports[report_id]
		if report and report.get("status") == "Completed":
			var relationship_key = get_relationship_key(user_id, report_id)
			var relationship = relationships.get(relationship_key, {})
			var points_data = points_allocated.get(relationship_key, {})
			
			history.append({
				"report_id": report_id,
				"relationship": relationship,
				"points_data": points_data
			})
	return history

func get_report_status(report_id: String) -> String:
	return reports.get(report_id, {}).get("status", "Unknown")

func get_employees_from_ecn(report_id: String) -> Array:
	var report = reports.get(report_id, {})
	return report.get("employees", [])

# Relationship Management
func get_relationship_key(user_id: String, report_id: String) -> String:
	return user_id + "_" + report_id

func mark_report_as_submitted(user_id: String, report_id: String) -> void:
	var relationship_key = get_relationship_key(user_id, report_id)
	if relationship_key in relationships:
		relationships[relationship_key]["is_submitted"] = true
		save_relationships()

func store_allocated_points(user_id: String, report_id: String, allocation_data: Dictionary) -> void:
	var relationship_key = get_relationship_key(user_id, report_id)
	points_allocated[relationship_key] = allocation_data

# File Management
func import_all_data_from_file(file_path: String) -> int:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Error: Could not open file ", file_path)
		return ErrorCode.FILE_ERROR
	
	var content = file.get_as_text()
	file.close()
	
	# Create a multipart form data request
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var url = "%s/api/%s/import/users" % [SERVER_URL, API_VERSION]
	var headers = ["Content-Type: multipart/form-data"]
	
	# Create form data
	var form_data = PackedByteArray()
	form_data.append_array("--boundary\r\n".to_utf8_buffer())
	form_data.append_array("Content-Disposition: form-data; name=\"file\"; filename=\"users.csv\"\r\n".to_utf8_buffer())
	form_data.append_array("Content-Type: text/csv\r\n\r\n".to_utf8_buffer())
	form_data.append_array(content.to_utf8_buffer())
	form_data.append_array("\r\n--boundary--\r\n".to_utf8_buffer())
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, form_data)
	if error != OK:
		print("Error making request: ", error)
		http_request.queue_free()
		return ErrorCode.NETWORK_ERROR
	
	# Wait for the request to complete
	var result = await http_request.request_completed
	http_request.queue_free()
	
	# Parse the response
	var response = result[0]
	var response_code = result[1]
	var response_headers = result[2]
	var response_body = result[3]
	
	if response_code != 200:
		print("Error: HTTP request failed with code ", response_code)
		return ErrorCode.NETWORK_ERROR
	
	return ErrorCode.SUCCESS

func export_all_data_to_file(file_path: String) -> int:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var url = "%s/api/%s/export/users" % [SERVER_URL, API_VERSION]
	var headers = ["Content-Type: application/json"]
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		print("Error making request: ", error)
		http_request.queue_free()
		return ErrorCode.NETWORK_ERROR
	
	# Wait for the request to complete
	var result = await http_request.request_completed
	http_request.queue_free()
	
	# Parse the response
	var response = result[0]
	var response_code = result[1]
	var response_headers = result[2]
	var response_body = result[3]
	
	if response_code != 200:
		print("Error: HTTP request failed with code ", response_code)
		return ErrorCode.NETWORK_ERROR
	
	var json = JSON.parse_string(response_body.get_string_from_utf8())
	if json == null:
		print("Error: Invalid JSON response")
		return ErrorCode.PARSE_ERROR
	
	# Save the data to file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		print("Error: Could not open file ", file_path)
		return ErrorCode.FILE_ERROR
	
	file.store_string(json.get("data", ""))
	file.close()
	
	return ErrorCode.SUCCESS

# Error codes
enum ErrorCode {
	SUCCESS = 0,
	FILE_ERROR = 1,
	NETWORK_ERROR = 2,
	PARSE_ERROR = 3
}

# Data Loading
func load_all_data() -> void:
	print("Starting load_all_data...")
	
	var user_id = get_user_id()
	if user_id.is_empty():
		print("Warning: No user ID set, cannot load data")
		return
	
	print("Loading all data for user: ", user_id)
	
	# Load user data
	print("Loading user data...")
	var new_user_data = await make_request("users/%s" % user_id, HTTPClient.METHOD_GET)
	if new_user_data.is_empty():
		print("Error: Failed to load user data")
		return
	local_player_data = new_user_data
	print("User data loaded: ", local_player_data)
	
	# Load resources
	print("Loading resources...")
	var new_resources = await make_request("users/%s/resources" % user_id, HTTPClient.METHOD_GET)
	if new_resources.is_empty():
		print("Error: Failed to load resources")
		return
	
	# Load game state
	print("Loading game state...")
	var new_game_state = await make_request("users/%s/game_state" % user_id, HTTPClient.METHOD_GET)
	if new_game_state.is_empty():
		print("Error: Failed to load game state")
		return
	game_state = new_game_state
	print("Game state loaded: ", game_state)
	
	# Load cosmetics
	print("Loading cosmetics...")
	var new_cosmetics = await make_request("users/%s/cosmetics" % user_id, HTTPClient.METHOD_GET)
	if new_cosmetics.is_empty():
		print("Error: Failed to load cosmetics")
		return
	cosmetics = new_cosmetics
	print("Cosmetics loaded: ", cosmetics)
	
	# Load shop items
	print("Loading shop items...")
	var new_shop_items = await make_request("shop/items", HTTPClient.METHOD_GET)
	if new_shop_items.is_empty():
		print("Error: Failed to load shop items")
		return
	shop_items = new_shop_items
	print("Shop items loaded: ", shop_items)
	
	# Load ECNs
	print("Loading ECNs...")
	var new_ecns = await make_request("users/%s/ecns" % user_id, HTTPClient.METHOD_GET)
	if new_ecns.is_empty():
		print("Error: Failed to load ECNs")
		return
	ecns = new_ecns.get("ecns", [])
	print("ECNs loaded: ", ecns)
	
	# Load local data
	print("Loading relationships...")
	load_relationships()
	
	print("Successfully loaded all data for user: ", user_id)

# Getters for persistent data
func get_persistent_user_data() -> Dictionary:
	return local_player_data

func get_persistent_resources() -> Dictionary:
	return local_player_data.get("resources", {"gas": 0, "scrap": 0})

func get_persistent_game_state() -> Dictionary:
	return game_state

func get_persistent_cosmetics() -> Dictionary:
	return cosmetics

func get_persistent_shop_items() -> Dictionary:
	return shop_items

func get_persistent_ecns() -> Array:
	return ecns

# Update the relationships handling
func save_relationships() -> void:
	var result = await import_all_data_from_file(relationships_path)
	if result != ErrorCode.SUCCESS:
		print("Error saving relationships: ", result)
		return
	print("Relationships saved successfully")

func load_relationships() -> void:
	var result = await export_all_data_to_file(relationships_path)
	if result != ErrorCode.SUCCESS:
		print("Error loading relationships: ", result)
		return
	
	var file = FileAccess.open(relationships_path, FileAccess.READ)
	if not file:
		print("Error: Could not open relationships file")
		return
	
	var json = JSON.parse_string(file.get_as_text())
	if json == null:
		print("Error: Invalid JSON in relationships file")
		return
	
	relationships = json

func save_data() -> void:
	var result = await import_all_data_from_file("user://data.json")
	if result != ErrorCode.SUCCESS:
		print("Error saving data: ", result)
		return
	
	print("Data saved successfully")
