extends CharacterBody2D

@onready var name_label = $NameLabel
@onready var rocket_body = $"Rocket Body"

# Cosmetic properties
var applied_cosmetics = {}

# Orbit parameters
var parent_planet: Area2D = null
var planet_position = Vector2.ZERO
var radius = 100
var angle = 0
var angular_speed = 1.0  # Radians per second
var is_orbiting = false

func _ready() -> void:
	if name_label:
		name_label.text = name  # Name will be rocket_id
	print("Rocket initialized: ", name)
	add_to_group("rockets")  # Add to rockets group for easy management
	
	# Load and apply any saved cosmetics
	load_cosmetics()

func load_cosmetics():
	# Only load cosmetics for the player's rocket
	if name == DataHandler.get_user_id():
		var user_cosmetics = DataHandler.get_user_cosmetics(name)
		for cosmetic_id in user_cosmetics:
			if user_cosmetics[cosmetic_id]:
				apply_cosmetic(cosmetic_id)

func apply_cosmetic(cosmetic_id: String):
	# Track which cosmetics are applied
	applied_cosmetics[cosmetic_id] = true
	
	# Apply the visual changes based on cosmetic ID
	match cosmetic_id:
		"red_rocket":
			rocket_body.modulate = Color(1.0, 0.2, 0.2)  # Red
		"blue_rocket":
			rocket_body.modulate = Color(0.2, 0.4, 1.0)  # Blue
		"gold_trim":
			# Add gold trim effect - in a real implementation, this might change
			# to a different texture or add a child sprite
			rocket_body.modulate = rocket_body.modulate.lightened(0.3)
			
	print("Applied cosmetic: ", cosmetic_id)

func clear_cosmetics():
	# Reset rocket appearance
	rocket_body.modulate = Color(1, 1, 1)  # Default white
	applied_cosmetics.clear()

func _physics_process(delta: float) -> void:
	if is_orbiting and parent_planet:
		# Update orbit
		angle += angular_speed * delta
		position = planet_position + Vector2(cos(angle), sin(angle)) * radius
		rotation = angle + PI  # Point in direction of travel
		
		# Keep name label readable
		if name_label:
			name_label.rotation = -rotation
		
		#print("Orbitting: ", position)
	#else:
		#print("Not orbitting. Planet: %s, is_orbitting: %s " % [position, is_orbiting])

func set_parent_planet(planet: Area2D):
	if parent_planet:
		# Remove from old planet's orbit tracking
		parent_planet.remove_rocket_from_orbit(name)
	
	parent_planet = planet
	if parent_planet:
		planet_position = parent_planet.global_position
		
		# Get orbit parameters from planet
		var orbit_data = parent_planet.get_orbit_data_for_rocket(name)
		if orbit_data:
			radius = orbit_data.get("radius", 100)
			angle = orbit_data.get("angle", 0)
		
		# Start orbiting
		is_orbiting = true
	else:
		# Stop orbiting if no parent planet
		is_orbiting = false

func get_rocket_id() -> String:
	return name