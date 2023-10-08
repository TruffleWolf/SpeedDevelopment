extends Area3D

@export var key_ID = 0



func activate(who):
	who.keys_held.append(key_ID)
	queue_free()
