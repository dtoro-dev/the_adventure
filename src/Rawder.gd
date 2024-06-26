extends CharacterBody2D

var GRAVITY : int = 4200 # 4500
const JUMP_SPEED : int = -1800

var touch_start_position = Vector2()
var touch_end_position = Vector2()
var touch_in_progress = false
var swipe_threshold = 100  # La distancia mínima para considerar un swipe
var touch_start_time = 0.0  # Para rastrear el tiempo de inicio del toque
var touch_duration_threshold = 0.2  # Umbral de duración para considerar un toque simple
var cruchdownCollision : bool = false
var swipe_down : bool = false
var swipe_up : bool = false
func _ready():
	set_process(true)

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start_position = event.position
			touch_in_progress = true
		else:
			touch_in_progress = false
			swipe_down = false
	elif event is InputEventScreenDrag and touch_in_progress:
		touch_end_position = event.position

func detect_swipe(end_position):
	var swipe_vector = end_position - touch_start_position
	if swipe_vector.length() > swipe_threshold and is_on_floor():
		if swipe_vector.y > 0:
			on_swipe_down()
		elif swipe_vector.y < 0:
			on_swipe_up()

func on_swipe_down():
	swipe_down = true

func on_swipe_up():
	swipe_up = true

func _physics_process(delta):	
	velocity.y += GRAVITY * delta
	if !get_parent().game_running:
		$Animation.play("idle")
	else:
		if get_parent().pause:
			$Animation.pause()
			return
		else:
			if touch_in_progress:
				detect_swipe(touch_end_position)
				
			if is_on_floor():
				if  Input.is_action_pressed("jump") or swipe_up:
					velocity.y = JUMP_SPEED
					$JumpSound.play()
					swipe_up = false
					cruchdownCollision = false
				elif Input.is_action_pressed("down") or swipe_down:
					cruchdownCollision = true
					$Animation.play("cruched_down")
				elif !swipe_down and !swipe_down:
					$Animation.play("run")
					cruchdownCollision = false
				
				if cruchdownCollision:
					$PolCruchedDown.disabled = false
					$PolRunner.disabled = true
				else:
					$PolCruchedDown.disabled = true
					$PolRunner.disabled = false
			else:
				$Animation.play("jump")
				
	move_and_slide()
