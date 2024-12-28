extends Node2D


#orbit params
var planet_position = Vector2.ZERO #Position of the planet
var radius = 100 #orbit radius
var angle = 0 #curr angle in rads
var angular_speed = 1.0 #orbit speed in rad/sec

func _ready() -> void:
	#set initial orbit pos and retrieve planet info
	planet_position = get_node("../Planet_1").global_position
	position = planet_position + Vector2(radius, 0)
	
func _process(delta):
	#update angle of rotation per time delta
	angle += angular_speed * delta
	
	#calculate new position and rotation of rocket
	position = planet_position + Vector2(cos(angle), sin(angle)) * radius
	rotation = angle + PI  #offset by PI/2 to rotate forward
