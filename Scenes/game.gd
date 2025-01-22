extends Node2D

@onready var name_label: Label = $Rocket/NameLabel
@onready var rocket: CharacterBody2D = $Rocket
@onready var planet_1: Area2D = $Planet_1

#TODO fix whatever mess I made in the game scene, cuz like wtf did I do?

func _ready() -> void:
	name_label.text = DataHandler.get_user_id()
	
	#set initial orbit pos and retrieve planet info for rocket
	planet_position = planet_1.global_position
	position = planet_position + Vector2(radius, 0)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#this seems like an awfully expensive solution to my problem, but I can't think of anything better
	name_label.rotation = global_rotation
	
	#rocket movement
	#update angle of rotation per time delta
	angle += angular_speed * delta
	#calculate new position and rotation of rocket
	rocket.position = planet_position + Vector2(cos(angle), sin(angle)) * radius
	rocket.rotation = angle + PI  #offset by PI/2 to rotate forward

#input reciever
func _input(event):
	pass

func add_to_leaderboard(EmployeeName, points,id, hat):
	var planet = $Planet_1
	planet.add_to_leaderboard(EmployeeName, points, id, hat)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu.tscn")

func traverse_planet(rocket_id):
	#Takes in the rocket/user id and attempts to traverse to the next planet, using up resources and their cost
	pass


#orbit params
var planet_position = Vector2.ZERO #Position of the planet
var radius = 100 #orbit radius
var angle = 0 #curr angle in rads
var angular_speed = 1.0 #orbit speed in rad/sec
