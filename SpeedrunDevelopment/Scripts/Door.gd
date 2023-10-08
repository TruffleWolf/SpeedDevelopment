extends Node3D


var open = false
var moving = false


func _on_button_pressed():
	if !moving:
		if open:
			$AnimationPlayer.play("Close")
		else:
			$AnimationPlayer.play("Open")
		open = !open
		moving = true


func _on_animation_player_animation_finished(anim_name):
	moving = false
