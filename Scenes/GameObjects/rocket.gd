extends CharacterBody2D

@onready var name_label = $NameLabel

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