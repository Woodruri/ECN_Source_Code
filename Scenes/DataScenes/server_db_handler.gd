extends Node

# Server configuration
var SERVER_URL = "http://localhost:8000"  # Can be changed in _ready()
const API_VERSION = "v1"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Check for command line argument for server URL
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg.begins_with("--server="):
			SERVER_URL = arg.split("=")[1]
			print("Using server URL: ", SERVER_URL)
			break

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Helper function to make HTTP requests
func make_request(endpoint: String, method: HTTPClient.Method, data: Dictionary = {}) -> Dictionary:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var url = "%s/api/%s/%s" % [SERVER_URL, API_VERSION, endpoint]
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(data) if not data.is_empty() else ""
	
	print("Making request to: ", url)
	print("Method: ", method)
	if not data.is_empty():
		print("Data: ", data)
	
	var error = http_request.request(url, headers, method, body)
	if error != OK:
		print("Error making request: ", error)
		http_request.queue_free()
		return {"error": "Failed to make request", "code": error}
	
	# Wait for the request to complete
	var result = await http_request.request_completed
	
	# Remove the HTTPRequest node
	http_request.queue_free()
	
	# Parse the response
	var response = result[0]
	var response_code = result[1]
	var response_headers = result[2]
	var response_body = result[3]
	
	if response_code != 200:
		print("Error: HTTP request failed with code ", response_code)
		print("Response body: ", response_body.get_string_from_utf8())
		return {"error": "HTTP request failed", "code": response_code}
	
	var json_response = JSON.parse_string(response_body.get_string_from_utf8())
	if json_response == null:
		print("Error: Failed to parse JSON response")
		return {"error": "Invalid JSON response"}
	
	return json_response

# User Management
func get_user_data(user_id: String) -> Dictionary:
	return await make_request("users/%s" % user_id, HTTPClient.METHOD_GET)

func update_user_data(user_id: String, data: Dictionary) -> Dictionary:
	return await make_request("users/%s" % user_id, HTTPClient.METHOD_PUT, data)

# Game State Management
func get_game_state(user_id: String) -> Dictionary:
	return await make_request("users/%s/game_state" % user_id, HTTPClient.METHOD_GET)

func update_game_state(user_id: String, data: Dictionary) -> Dictionary:
	return await make_request("users/%s/game_state" % user_id, HTTPClient.METHOD_POST, data)

# Leaderboard Management
func get_global_leaderboard(limit: int = 10) -> Array:
	var response = await make_request("leaderboard/global?limit=%d" % limit, HTTPClient.METHOD_GET)
	return response.get("entries", [])

func get_planet_leaderboard(planet_id: String, limit: int = 10) -> Array:
	var response = await make_request("leaderboard/planet/%s?limit=%d" % [planet_id, limit], HTTPClient.METHOD_GET)
	return response.get("entries", [])

# Shop Management
func get_shop_items() -> Dictionary:
	return await make_request("shop/items", HTTPClient.METHOD_GET)

func purchase_item(user_id: String, item_id: String) -> Dictionary:
	return await make_request("shop/purchase", HTTPClient.METHOD_POST, {
		"user_id": user_id,
		"item_id": item_id
	})

# Cosmetic Management
func get_user_cosmetics(user_id: String) -> Dictionary:
	return await make_request("cosmetics/%s" % user_id, HTTPClient.METHOD_GET)

func update_user_cosmetics(user_id: String, cosmetics: Dictionary) -> Dictionary:
	return await make_request("cosmetics/%s" % user_id, HTTPClient.METHOD_PUT, cosmetics)

# Resource Management
func get_user_resources(user_id: String) -> Dictionary:
	return await make_request("resources/%s" % user_id, HTTPClient.METHOD_GET)

func update_user_resources(user_id: String, resources: Dictionary) -> Dictionary:
	return await make_request("resources/%s" % user_id, HTTPClient.METHOD_PUT, resources)

# ECN Management
func get_user_ecns(user_id: String) -> Array:
	var response = await make_request("ecns/user/%s" % user_id, HTTPClient.METHOD_GET)
	return response.get("ecns", [])

func submit_ecn(user_id: String, ecn_id: String) -> Dictionary:
	return await make_request("ecns/submit", HTTPClient.METHOD_POST, {
		"user_id": user_id,
		"ecn_id": ecn_id
	})

# Initialize all data for a new user
func initialize_user_data(user_id: String) -> Dictionary:
	return await make_request("users/initialize", HTTPClient.METHOD_POST, {
		"user_id": user_id
	})
