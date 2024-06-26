extends Control

var sumpt_scene = preload("res://scenes/Stump.tscn")
var rock_scene = preload("res://scenes/Rock.tscn")
var barrel_scene = preload("res://scenes/Barrel.tscn")
var box_scene = preload("res://scenes/Box.tscn")
var bird_scene = preload("res://scenes/Bird.tscn")
var obstacle_types := [
	sumpt_scene,
	rock_scene,
	barrel_scene,
	box_scene
]
var obstacles : Array
var bird_heights := [360, 430]
const RAWDER_START_POS := Vector2i(0, 0)
const CAM_START_POS := Vector2i(0, 0)
var difficulty
const MAX_DIFFICULTY : int = 2
var score : int
const SCORE_MODIFIER : int = 10
var high_score : int
var speed : float
const START_SPEED : float = 10.0
const SPEED_MODIFIER : int = 5000
const MAX_SPEED : int = 25
var screen_size : Vector2i
var ground_height : int
var ground_width : int
var game_running : bool
var last_obs
var game_over : bool
var pause : bool = false
var sound : bool = true
# Called when the node enters the scene tree for the first time.
func _ready():
	$Rawder.get_node("DeadSound").stop()
	ground_height = $FloorControl/Floor/Sprite2D.texture.get_height()
	$GameOverHUD/Background/RestartBtn.pressed.connect(new_game)
	$AudioStage.play()
	$AudioStage.stream.loop = true
	toggle_pause(false)
	new_game()

func new_game():
	# reset variables
	score = 0
	show_score()
	game_running = false
	get_tree().paused = false
	difficulty = 0
	
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	# reset Nodes
	screen_size = get_window().size
	$Rawder.position = RAWDER_START_POS
	$Rawder.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$FloorControl/Floor.position = Vector2i(0, 0)
	$GameOverHUD/Background.hide()
	$HUD/PauseBtn.visible = true

func _input(event):
	if Input.is_action_just_pressed("pause"):
		pause = !pause
		toggle_pause(pause)
		if (pause):
			$Rawder/Animation.pause()
		else:
			$Rawder/Animation.play("run")

func _process(_delta):
	if game_running:
		if !pause:
			speed = START_SPEED + score / SPEED_MODIFIER
			if speed > MAX_SPEED:
				speed = MAX_SPEED
			adjust_difficulty()
			
			generate_obs()
			
			$Rawder.position.x += speed
			$Camera2D.position.x += speed
			score += speed
			show_score()
			if $Camera2D.position.x - $FloorControl/Floor.position.x > screen_size.x:
				$FloorControl/Floor.position.x += screen_size.x - 190
			
			for obs in obstacles:
				if obs.position.x < ($Camera2D.position.x - screen_size.x):
					remove_obs(obs)
	else:
		if Input.is_action_pressed("jump") or $Rawder.touch_in_progress:
			game_running = true
			$HUD/LabelStart.visible = false

func _on_exit_btn_pressed():
	get_tree().quit()

func _on_reanudar_btn_pressed():
	$Rawder/Animation.play("run")
	pause = false
	toggle_pause(pause)

func _on_texture_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_pause_btn_pressed():
	$Rawder/Animation.pause()
	pause = true
	toggle_pause(pause)

func toggle_pause(paused):
	$HUD/PauseBackground.visible = paused
	$HUD/PauseBtn.visible = !paused
	$AudioStage.stream_paused = paused
	if paused == true:
		if sound == true:
			$HUD/PauseBackground/SoundOnBtn.visible = true
			$HUD/PauseBackground/SoundOffBtn.visible = false
		else:
			$HUD/PauseBackground/SoundOnBtn.visible = false
			$HUD/PauseBackground/SoundOffBtn.visible = true
	else:
		$HUD/PauseBackground/SoundOnBtn.visible = false
		$HUD/PauseBackground/SoundOffBtn.visible = false
	

func _on_sound_on_btn_pressed():
	sound = false
	$AudioStage.volume_db = -100
	$HUD/PauseBackground/SoundOnBtn.visible = false
	$HUD/PauseBackground/SoundOffBtn.visible = true
	

func _on_sound_off_btn_pressed():
	sound = true
	$AudioStage.volume_db = -15
	$HUD/PauseBackground/SoundOnBtn.visible = true
	$HUD/PauseBackground/SoundOffBtn.visible = false
	
func show_score():
	$HUD.get_node("LabelScore/Points").text = str(score / SCORE_MODIFIER)

func generate_obs():
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(300, 600):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + score + 100 + (i * 100)
			var obs_y : int = screen_size.y - (ground_height  * 3)
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
		if difficulty == MAX_DIFFICULTY:
			if (randi() % 2) == 0:
				obs = bird_scene.instantiate()
				var obs_x : int = screen_size.x + score + 100
				var obs_y : int = bird_heights[randi() % bird_heights.size()]
				add_obs(obs, obs_x, obs_y)

func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)

func adjust_difficulty():
	difficulty = score / SCORE_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func remove_obs(obs):
	obs.queue_free()
	obstacles.erase(obs)
	
func hit_obs(body):
	if body.name == "Rawder":
		show_game_over()

func show_game_over():
	check_high_score()
	$GameOverHUD/Background.show()
	$HUD/PauseBtn.visible = false
	get_tree().paused = true
	game_running = false

func check_high_score():
	if score > high_score:
		high_score = score
		$HUD/LabelHighScore/HighPoints.text = str(score / SCORE_MODIFIER)
