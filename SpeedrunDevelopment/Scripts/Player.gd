extends CharacterBody3D


@onready var active_weapon = 3
@export var RUN_SPEED = 5.0
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


func _ready():
	add_to_group("Player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if playmode:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * SettingsManager.look_sens)
			$Camera3D.rotate_x(-event.relative.y * SettingsManager.look_sens)
		
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x,deg_to_rad(-88),deg_to_rad(88))
	


func _physics_process(delta):
	if playmode:
		
		if Input.is_action_just_pressed("ui_cancel"):
			playmode = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		
		
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
	

func get_grabpoint():
	return $Camera3D/HoldPoint.global_transform


func _on_area_3d_body_entered(body):
	if !body.is_in_group("Player"):
		floor_collisions.append(body)


func _on_area_3d_body_exited(body):
	floor_collisions.erase(body)
