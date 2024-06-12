extends Node

var sumpt_scene = preload("res://scenes/stump.tscn")
var rock_scene = preload("res://scenes/rock.tscn")
var barrel_scene = preload("res://scenes/barrel.tscn")
var box_scene = preload("res://scenes/box.tscn")
var bird_scene = preload("res://scenes/bird.tscn")
var obstacle_types := [
	sumpt_scene,
	rock_scene,
	barrel_scene,
	box_scene
]
var obstacles : Array
var bird_heights := [360, 390]
# 3807
const RAWDER_START_POS := Vector2i(150, 485)
const CAM_START_POS := Vector2i(576,324)
var difficulty
const MAX_DIFFICULTY : int = 2
var score : int
const SCORE_MODIFIER : int = 10
var high_score : int
var speed : float
const START_SPEED : float = 7.0
const SPEED_MODIFIER : int = 5000
const MAX_SPEED : int = 25
var screen_size : Vector2i
var ground_height : int
var game_running : bool
var game_over_flag : bool
var last_obs

func _ready():
	screen_size = get_window().size
	ground_height = $Floor.get_node("Sprite2D").texture.get_height()
	
	$HUD.get_node("ExitBtn").pressed.connect(exit_game)
	$HUD.get_node("RestartBtn").pressed.connect(new_game)
	new_game()

func new_game():
	$Rawder.get_node("DeadSound").stop()
	$AudioStage.play()
	score = 0
	show_score()
	game_running = false
	get_tree().paused = false
	difficulty = 0
	game_over_flag = false
	
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	$Rawder.position = RAWDER_START_POS
	$Rawder.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Floor.position = Vector2i(0, 0)
	
	$HUD.get_node("StartLabel").show()
	$HUD.get_node("ExitBtn").show()
	$HUD.get_node("RestartBtn").hide()

func _process(_delta):
	if game_running:
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		adjust_difficulty()
		generate_obs()
		
		$Rawder.position.x += speed
		$Camera2D.position.x += speed
		
		#update score
		score += int (speed)
		show_score()
		
		if $Camera2D.position.x - $Floor.position.x > screen_size.x  * 1.5:
			$Floor.position.x += screen_size.x - 190
			
		for obs in obstacles:
			if obs.position.x < ($Camera2D.position.x-screen_size.x):
				remove_obs(obs)
	else:
		if game_over_flag:
			if $Rawder.position.y < -100:
				$Rawder.position.y = -300
			else:
				$Rawder.position.y -= 10
		 
		if Input.is_action_pressed("ui_accept") and !game_over_flag:
			game_running = true
			game_over_flag = false
			$HUD.get_node("StartLabel").hide()
			$HUD .get_node("RestartBtn").hide()
			$HUD.get_node("ExitBtn").hide()
	
func generate_obs():
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(300, 500):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + score + 100 + (i * 100)
			var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) - 50
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

func remove_obs(obs):
	obs.queue_free()
	obstacles.erase(obs)

func hit_obs(body):
	if body.name == "Rawder":
		game_over()
		
func show_score ():
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score / SCORE_MODIFIER)
	
func check_high_score():
	if score > high_score:
		high_score = score
		$HUD.get_node("HighScoreLabel").text = "HIGH SCORE: " + str(score / SCORE_MODIFIER)

func adjust_difficulty():
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func game_over():
	$AudioStage.stop()
	$Rawder.get_node("DeadSound").play()
	check_high_score()
	game_over_flag = true
	game_running = false
	
	$HUD.get_node("ExitBtn").show()
	$HUD.get_node("RestartBtn").show()

func exit_game():
	get_tree().quit()
