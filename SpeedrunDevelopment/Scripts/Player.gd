extends CharacterBody3D


@onready var active_weapon = 3
@export var RUN_SPEED = 10.0
const WALK_SPEED = 2.5
const CROUCH_SPEED = 2.0
const MOVE_ACCEL = 0.1
@export var JUMP_FORCE = 10
var direction = Vector3()
var fall_speed = 0.1
var accuracy_mod = 0.0
#running, walking, crouching
@onready var playmode = true
var floor_collisions = []
var keys_held = []
var held_prop = null
@onready var footstep_primed = true
@onready var target_light_energy = 3.0
@onready var light_rotation = Quaternion($Camera3D/SpotLight3D.global_transform.basis)


func _ready():
	add_to_group("Player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Ambience.play()


func _input(event):
	if playmode:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * SettingsManager.look_sens)
			$Camera3D.rotate_x(-event.relative.y * SettingsManager.look_sens)
		
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x,deg_to_rad(-88),deg_to_rad(88))
	


func _physics_process(delta):
	if playmode:
		
		light_rotation = light_rotation.slerp(Quaternion($Camera3D.global_transform.basis),.3)
		$Camera3D/SpotLight3D.global_transform.basis = Basis(light_rotation)
		$Camera3D/HUD/DebugLabel.text = str($Camera3D/SpotLight3D.global_rotation)+"/"+str($Camera3D.global_rotation)
		
		if abs($Camera3D/SpotLight3D.light_energy- target_light_energy)<.01:
			target_light_energy = GameManager.RNG.randf_range(.1,3.0)
		elif $Camera3D/SpotLight3D.light_energy<target_light_energy:
			$Camera3D/SpotLight3D.light_energy +=.001
		elif $Camera3D/SpotLight3D.light_energy>target_light_energy:
			$Camera3D/SpotLight3D.light_energy -=.001
		if Input.is_action_just_pressed("ui_cancel"):
			playmode = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		
		if Input.is_action_just_pressed("Flashlight"):
			if $Camera3D/SpotLight3D.visible:
				$LightOff.play()
			else:
				$LightOn.play()
				$Camera3D/SpotLight3D.light_energy = 3.0
			$Camera3D/SpotLight3D.visible = !$Camera3D/SpotLight3D.visible
		
		if $Camera3D/InteractRay.is_colliding():
			
			$Camera3D/HUD/Center/InteractIcon.show()
			
			if Input.is_action_just_pressed("Interact"):
				
				if held_prop ==null:
					
					$Camera3D/InteractRay.get_collider().activate(self)
				elif held_prop != null:
					held_prop.drop()
					held_prop = null
		else:
			$Camera3D/HUD/Center/InteractIcon.hide()
		
		movement()
		
		
	
	else:
		if Input.is_action_just_pressed("ui_cancel"):
			playmode = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	

func movement():
	direction = Vector3()
	if Input.is_action_pressed("Forward"):
		direction -= transform.basis.z
	elif Input.is_action_pressed("Back"):
		direction += transform.basis.z
	if Input.is_action_pressed("Left"):
		direction -= transform.basis.x
	elif Input.is_action_pressed("Right"):
		direction += transform.basis.x
	
	
	if is_on_floor():
		if direction == Vector3():
			fall_speed = max(fall_speed,0)
	else:
		fall_speed -= GameManager.gravity
	if is_on_ceiling():
		fall_speed = -.1
	elif floor_collisions.size()>0 and Input.is_action_just_pressed("Jump"):
		fall_speed = JUMP_FORCE
	
	direction = direction.normalized()
	velocity = velocity.lerp(direction*RUN_SPEED,MOVE_ACCEL)
	
	velocity.y = fall_speed
	move_and_slide()
	
#	if direction.length()> 0 and footstep_primed:
#		$RightFoot.play()
#		footstep_primed = false

func get_grabpoint():
	return $Camera3D/HoldPoint.global_transform


func _on_area_3d_body_entered(body):
	if !body.is_in_group("Player"):
		floor_collisions.append(body)


func _on_area_3d_body_exited(body):
	floor_collisions.erase(body)


func _on_leftfoot_finished():
	if direction.length() > 0:
		$RightFoot.play()
		return
	footstep_primed = true
	


func _on_right_foot_finished():
	if direction.length() > 0:
		$LeftFoot.play()
		return
	footstep_primed = true
