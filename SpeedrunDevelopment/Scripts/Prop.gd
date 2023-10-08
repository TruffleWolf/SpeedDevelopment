extends RigidBody3D


var holder = []


func _physics_process(delta):
	
	var target_postion = global_transform.origin
	var target_rotation = global_rotation
	for h in holder:
		target_postion = target_postion.lerp(h.get_grabpoint().origin,.9)
		target_rotation = target_rotation.lerp(-h.get_grabpoint().basis.z,.9)
		print(str(target_rotation))
		
	global_transform.origin = target_postion
	global_rotation = target_rotation


func activate(who):
	
	who.held_prop = self
	holder.append(who)
	

func drop():
	holder = []
	
