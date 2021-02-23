extends Node
# Generation
# Class that creates all games in a generation, and handles them
signal finished

var Game = load("res://classes/Game.gd")
var Brain = load("res://classes/Brain.gd")
var no_individuals
var main_child = 0
var update_frames = 25
var movement_frames = int(update_frames/5)
var individuals_update_frames = update_frames*200
var frames_count = 0
var is_update_frame = false
var is_movement_frame = false
var engine_fps = [60, 120, 180, 240]
var engine_selected = 0
var brains
var max_pieces
var trials_per_game

func _init(brains_input, max_pieces_input, trials_per_game_input):
	self.brains = brains_input
	self.max_pieces = max_pieces_input
	self.trials_per_game = trials_per_game_input

func _ready():
	# Set labels
	get_parent().get_parent().get_node("HUD").get_node("Left").text = \
		str(brains.size())
	# Create individual games
	for i in range(brains.size()):
		var new_individual = Game.new(i, brains[i], max_pieces, trials_per_game)
		add_child(new_individual)
	# Select top 16 to display them
	select_main_individuals_for_visualization()
	
func _physics_process(_delta):
	frames_count += 1
	# Handles the increase and decrease in game speed
	if Input.is_action_pressed("ui_down"):
		if engine_selected > 0:
			engine_selected -= 1
		Engine.iterations_per_second = engine_fps[engine_selected]
	if Input.is_action_pressed("ui_up"):
		if engine_selected < 3:
			engine_selected += 1
		Engine.iterations_per_second = engine_fps[engine_selected]
		
	# Checks if it's an update frame to force the piece to move
	if frames_count % update_frames == 0:
		is_update_frame = true
	else:
		is_update_frame = false
	
	# Checks if it's a movement frame to move if a movement has been selected
	if frames_count % movement_frames == 0:
		is_movement_frame = true
	else:
		is_movement_frame = false	
		
	# Update top 16 games visualization based on scores
	if frames_count % individuals_update_frames == 0:
		select_main_individuals_for_visualization()
		
	# Update remaining alive games label
	var still_alive = remaining_individuals()
	get_parent().get_parent().get_node("HUD").get_node("Left").text = \
		str(still_alive)
		
	if still_alive == 0:
		emit_signal("finished")
	
	
func select_main_individuals_for_visualization():
	var games = []
	for game in get_children():
		game.make_invisible()
		games.append(game)
	
	games.sort_custom(CustomSorter, "sort")
	
	# Select top individual for the main visualization
	games[0].make_main(0, 0)
	# Select individuals for the other 15
	for i in range(5):
		games[1 + i].make_secondary(462 + i * 124.667, 0)
		games[6 + i].make_secondary(462 + i * 124.667, 234.667)
		games[11 + i].make_secondary(462 + i * 124.667, 469.333)
	
func remaining_individuals():
	# Count remaining alive individuals
	var still_alive = 0
	for child in get_children():
		if !child.finished_game:
			still_alive += 1
	return still_alive
	
func copy_brains():
	# Self explanatory I think
	var new_brains = []
	for game in get_children():
		var new_brain = Brain.new(game.brain.a, game.brain.b, game.brain.c, 
			game.brain.d)
		new_brain.score = game.score
		new_brains.append(new_brain)
		
	return new_brains
	
class CustomSorter:
	static func sort(a, b):
		if a.score > b.score:
			return true
		return false
