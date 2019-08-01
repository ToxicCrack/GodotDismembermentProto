extends KinematicBody

const GRAVITY = 9.8

export(float,10.0, 30.0) var speed = 5.0
export(float,1.0, 10.0) var mass = 8.0
export(float,0.1, 3.0, 0.1) var gravity_scl = 1.0

var gravity_speed = 0

var player
var dead = false
var dying = false
onready var gameManager = get_tree().get_current_scene()


# fatal: deadly?
# need_one: one of these body parts have to exist. Otherwise the actual part will be destroyed. this prevents floating body parts
# connected: if the actual part gets destroyed, the connected parts are destroyed as well

var hitpoints = {
  "head_uppr_r_bone": {"health": 25, "fatal": false, "need_one": ["head_mid_r_bone", "head_mid_m_bone", "head_mid_l_bone"]},
  "head_uppr_m_bone": {"health": 25, "fatal": false, "need_one": ["head_mid_r_bone", "head_mid_m_bone", "head_mid_l_bone"]},
  "head_uppr_l_bone": {"health": 25, "fatal": false, "need_one": ["head_mid_r_bone", "head_mid_m_bone", "head_mid_l_bone"]},
  "head_mid_r_bone": {"health": 25, "fatal": false, "need_one": ["head_lwr_r_bone", "head_lwr_m_bone", "head_lwr_l_bone"]},
  "head_mid_m_bone": {"health": 50, "fatal": true, "need_one": ["head_lwr_r_bone", "head_lwr_m_bone", "head_lwr_l_bone"]},
  "head_mid_l_bone": {"health": 25, "fatal": false, "need_one": ["head_lwr_r_bone", "head_lwr_m_bone", "head_lwr_l_bone"]},
  "head_lwr_r_bone": {"health": 25, "fatal": false},
  "head_lwr_m_bone": {"health": 50, "fatal": true},
  "head_lwr_l_bone": {"health": 25, "fatal": false},
  
  "body": {"health": -1, "fatal": false},
  
  "arm_uppr_l_bone": {"health": 25, "fatal": false, "connected": ["arm_lwr_l_bone"]},
  "arm_lwr_l_bone": {"health": 25, "fatal": false},
  "arm_uppr_r_bone": {"health": 25, "fatal": false, "connected": ["arm_lwr_r_bone"]},
  "arm_lwr_r_bone": {"health": 25, "fatal": false},
  
  "leg_uppr_l_bone": {"health": 25, "fatal": false, "connected": ["leg_lwr_l_bone", "col_leg_lwr_l", "col_leg_uppr_l"]},
  "leg_lwr_l_bone": {"health": 25, "fatal": false, "connected": ["col_leg_lwr_l"]},
  "leg_uppr_r_bone": {"health": 25, "fatal": false, "connected": ["leg_lwr_r_bone", "col_leg_lwr_r", "col_leg_uppr_r"]},
  "leg_lwr_r_bone": {"health": 25, "fatal": false, "connected": ["col_leg_lwr_r"]},
 }

# Called when the node enters the scene tree for the first time.
func _ready():
  set_process(true)
  set_process_input(true)
  
  self.player = get_tree().get_nodes_in_group("player")[0]
  $AnimationPlayer.playback_speed = 5
  $AnimationPlayer.play("walk")
  
  
func _physics_process(delta):
  if(not self.gameManager.running):
    $AnimationPlayer.stop()
    return
  gravity_speed -= GRAVITY * gravity_scl * mass * delta
  var velocity = Vector3()
  if(self.hitpoints["leg_uppr_l_bone"]["health"] <= 0 or self.hitpoints["leg_uppr_r_bone"]["health"] <= 0 or self.hitpoints["leg_lwr_l_bone"]["health"] <= 0 or self.hitpoints["leg_lwr_r_bone"]["health"] <= 0):
    self.speed = 2.5
  if((self.hitpoints["leg_uppr_l_bone"]["health"] > 0 or self.hitpoints["leg_uppr_r_bone"]["health"] > 0) and not dead):
    var lookPos = player.get_transform().origin
    look_at(lookPos,Vector3(0,1,0))
    
    velocity = self.get_transform().origin.direction_to(lookPos).normalized() * speed
  velocity.y = gravity_speed

  gravity_speed = move_and_slide(velocity).y
  
  if(self.dying):
    self.rotation_degrees.x += delta * 300
    if(self.rotation_degrees.x >= 90):
      self.dying = false
      $AnimationPlayer.stop()
      self.translation.y = 0.5
  

func hit(collider, collision_point, damage):
  if(not self.gameManager.running):
    return
  #print(collider.get_parent().name)
  var particles = $BloodParticles.duplicate()
  self.add_child(particles)
  particles.global_transform.origin = collision_point
  particles.emitting = true
  #TODO: queue_free particles after a while (Timer)
  
  collider.get_parent().name
  
  var limbName = collider.get_parent().name
  if(self.hitpoints.has(limbName)):
    if(self.hitpoints[limbName]["health"] > 0):
      self.hitpoints[limbName]["health"] -= damage
      if(self.hitpoints[limbName]["health"] <= 0):
        #collider.get_parent().get_parent().queue_free()
        for child in collider.get_parent().get_parent().get_children():
            child.queue_free()
        if(self.hitpoints[limbName].has("connected")):
          for connected in self.hitpoints[limbName]["connected"]:
            var conn = self.find_node(connected)
            if(conn):
              if(conn is CollisionShape):
                conn.disabled = true
                conn.queue_free()
              else:
                conn.get_parent().queue_free()
                
        self.checkBodyParts()
        
        if(self.hitpoints[limbName]["fatal"]):
          #die
          #self.queue_free()
          var particles2 = $BloodParticles.duplicate()
          self.add_child(particles2)
          particles2.scale = Vector3(3, 3, 3)
          particles2.translation = Vector3(0, 2.259, -1)
          particles2.emitting = true
          self.die()

func checkBodyParts():
  for hitpoint in self.hitpoints:
    if(self.hitpoints[hitpoint].has("need_one")):
      var oneExist = false
      for needed in self.hitpoints[hitpoint]["need_one"]:
        if(self.hitpoints.has(needed)):
          if(self.hitpoints[needed]["health"] > 0):
            oneExist = true
      if(not oneExist):
        #remove Body Part
        self.hitpoints[hitpoint]["health"] = 0
        var n = self.find_node(hitpoint)
        if(n):
          for child in n.get_parent().get_children():
            child.queue_free()
          yield(get_tree(),"idle_frame")
          self.checkBodyParts()
        

func die():
  if(not self.dead):
    self.dead = true
    self.dying = true

func _on_KillArea_body_entered(body):
  if(body.is_in_group("player") and not dead):
    
    self.gameManager.gameOver()