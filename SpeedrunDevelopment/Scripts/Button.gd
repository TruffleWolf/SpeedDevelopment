extends Area3D

signal pressed 

@export var key_required = -1


func activate(who):
	if key_required == -1 or who.keys_held.has(key_required):
		emit_signal("pressed")
