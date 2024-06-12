extends CharacterBody2D

var GRAVITY : int = 4500
const JUMP_SPEED : int = -1800


func _physics_process(delta):
	velocity.y += GRAVITY * delta
	
	if get_parent().game_over_flag:
		$Animation.play("dead")
		GRAVITY = 200
	else:
		GRAVITY = 4500
		if is_on_floor():
			if not get_parent().game_running:  
				$Animation.play("idle")
			else: 
				$RunCol.disabled = false
				if Input.is_action_pressed("ui_accept"):
					velocity.y = JUMP_SPEED
					$JumpSound.play()
				elif Input.is_action_pressed("ui_down"):
					$Animation.play("idle")
					$RunCol.disabled = true
				else:
					$Animation.play("run")
		else:
			$Animation.play("jump")
	
	move_and_slide()
