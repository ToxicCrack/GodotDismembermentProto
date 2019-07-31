extends Node

onready var spawn_point = $Spawn_Point

var running = true
var hud 

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	spawn_point.translation = Vector3(0,35,0)
	self.hud = get_tree().get_nodes_in_group("hud")[0]


func _input(event):
  if Input.is_action_just_pressed("ui_cancel"):
    if(Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE):
      Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    else:
      Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_Dead_Zone_body_entered(body):
	print("DEAD ZONE!")
	body.translation = spawn_point.translation

func gameOver():
  self.running = false
  Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
  self.hud.get_node("GameOverDialog").popup()
  
func restart():
  get_tree().reload_current_scene()