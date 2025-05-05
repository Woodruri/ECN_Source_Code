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
	# Load cosmetics for all rockets, not just the player's rocket
	var user_cosmetics = DataHandler.get_persistent_cosmetics()
	for cosmetic_id in user_cosmetics:
		if user_cosmetics[cosmetic_id]:
			apply_cosmetic(cosmetic_id)

func apply_cosmetic(cosmetic_id: String):
	# Track which cosmetics are applied
	applied_cosmetics[cosmetic_id] = true
	
	# Apply the visual changes based on cosmetic ID
	match cosmetic_id:
		"red_rocket":
			# Use a more subtle tint for red
			rocket_body.modulate = Color(1.0, 0.7, 0.7)  # Light red tint
			# Add a subtle glow effect
			rocket_body.material = create_glow_material(Color(1.0, 0.2, 0.2, 0.3))
		"blue_rocket":
			# Use a more subtle tint for blue
			rocket_body.modulate = Color(0.7, 0.8, 1.0)  # Light blue tint
			# Add a subtle glow effect
			rocket_body.material = create_glow_material(Color(0.2, 0.4, 1.0, 0.3))
		"gold_trim":
			# Add gold trim effect - more subtle
			rocket_body.modulate = Color(1.0, 0.9, 0.7)  # Light gold tint
			# Add a shimmer effect
			rocket_body.material = create_shimmer_material()
		"blue_exhaust":
			# Apply blue exhaust effect
			apply_exhaust_effect(Color(0.2, 0.4, 1.0, 0.7))
		"green_exhaust":
			# Apply green exhaust effect
			apply_exhaust_effect(Color(0.2, 1.0, 0.4, 0.7))
		"purple_exhaust":
			# Apply purple exhaust effect
			apply_exhaust_effect(Color(0.6, 0.2, 1.0, 0.7))
		"small_wings":
			# Apply small wings effect
			apply_wings_effect("small")
		"large_wings":
			# Apply large wings effect
			apply_wings_effect("large")
		"bat_wings":
			# Apply bat wings effect
			apply_wings_effect("bat")
			
	print("Applied cosmetic: ", cosmetic_id)
	
	# After applying a new cosmetic, reapply all active cosmetics to ensure they're all visible
	reapply_all_cosmetics()

func reapply_all_cosmetics():
	# Store the current cosmetics
	var current_cosmetics = applied_cosmetics.duplicate()
	
	# Clear all cosmetics
	clear_cosmetics()
	
	# Reapply each cosmetic
	for cosmetic_id in current_cosmetics:
		if current_cosmetics[cosmetic_id]:
			# Apply the cosmetic without tracking it again
			apply_cosmetic_visuals(cosmetic_id)

func apply_cosmetic_visuals(cosmetic_id: String):
	# Apply only the visual changes without tracking
	match cosmetic_id:
		"red_rocket":
			# Use a more subtle tint for red
			rocket_body.modulate = Color(1.0, 0.7, 0.7)  # Light red tint
			# Add a subtle glow effect
			rocket_body.material = create_glow_material(Color(1.0, 0.2, 0.2, 0.3))
		"blue_rocket":
			# Use a more subtle tint for blue
			rocket_body.modulate = Color(0.7, 0.8, 1.0)  # Light blue tint
			# Add a subtle glow effect
			rocket_body.material = create_glow_material(Color(0.2, 0.4, 1.0, 0.3))
		"gold_trim":
			# Add gold trim effect - more subtle
			rocket_body.modulate = Color(1.0, 0.9, 0.7)  # Light gold tint
			# Add a shimmer effect
			rocket_body.material = create_shimmer_material()
		"blue_exhaust":
			# Apply blue exhaust effect
			apply_exhaust_effect(Color(0.2, 0.4, 1.0, 0.7))
		"green_exhaust":
			# Apply green exhaust effect
			apply_exhaust_effect(Color(0.2, 1.0, 0.4, 0.7))
		"purple_exhaust":
			# Apply purple exhaust effect
			apply_exhaust_effect(Color(0.6, 0.2, 1.0, 0.7))
		"small_wings":
			# Apply small wings effect
			apply_wings_effect("small")
		"large_wings":
			# Apply large wings effect
			apply_wings_effect("large")
		"bat_wings":
			# Apply bat wings effect
			apply_wings_effect("bat")

func apply_exhaust_effect(color: Color):
	# This would create an exhaust particle effect
	# For now, we'll just add a simple visual indicator
	var exhaust = ColorRect.new()
	exhaust.size = Vector2(20, 10)
	exhaust.position = Vector2(-20, 0)
	exhaust.color = color
	rocket_body.add_child(exhaust)
	
	# Add a simple animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(exhaust, "scale:x", 1.5, 0.5)
	tween.tween_property(exhaust, "scale:x", 1.0, 0.5)

func apply_wings_effect(wing_type: String):
	# This would add wings to the rocket
	# For now, we'll just add a simple visual indicator
	var wing = ColorRect.new()
	
	match wing_type:
		"small":
			wing.size = Vector2(30, 15)
		"large":
			wing.size = Vector2(50, 25)
		"bat":
			wing.size = Vector2(40, 20)
	
	wing.position = Vector2(0, -10)
	wing.color = Color(0.8, 0.8, 0.8, 0.8)
	rocket_body.add_child(wing)

func create_glow_material(color: Color) -> ShaderMaterial:
	var material = ShaderMaterial.new()
	var shader = load("res://Shaders/glow.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("glow_color", color)
		material.set_shader_parameter("glow_intensity", 0.3)  # Reduced intensity
	return material

func create_shimmer_material() -> ShaderMaterial:
	var material = ShaderMaterial.new()
	var shader = load("res://Shaders/shimmer.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("shimmer_color", Color(1.0, 0.8, 0.2, 0.5))  # More transparent
		material.set_shader_parameter("shimmer_speed", 2.0)
	return material

func clear_cosmetics():
	# Reset rocket appearance
	rocket_body.modulate = Color(1, 1, 1)  # Default white
	rocket_body.material = null  # Remove any custom materials
	
	# Remove any child nodes added by cosmetics
	for child in rocket_body.get_children():
		child.queue_free()
	
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
