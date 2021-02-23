# Game
# Class that handles the connection between the brain and the actual pieces'
# movemnent
extends Node2D

var id
var PiecesGrid = load("res://classes/PiecesGrid.gd")
var pieces_grid
var brain
var is_main = false
var parent
var score = 0
var max_pieces
var max_runs
var no_runs = 0
var finished_game = false
var queued_free_pieces_grid = false
var grid_visible = false
var next_piece_invisible = true
var id_label

func _init(id_in, brain_in, max_pieces_in, trials_per_game_in):
	self.id = id_in
	self.brain = brain_in
	self.max_pieces = max_pieces_in
	self.max_runs = trials_per_game_in

func _ready():
	# Create actual visible grid for the pieces
	add_pieces_grid()
	parent = get_parent()
	
	# Show individual game ID (yellow number on top of all games)
	id_label = Label.new()
	id_label._set_position(Vector2(280, 50))
	id_label.text = str(id)
	id_label.visible = false
	var dynamic_font = DynamicFont.new()
	dynamic_font.font_data = load("res://assets/font/pixelart.ttf")
	dynamic_font.size = 40
	id_label.add_font_override("font", dynamic_font)
	id_label.add_color_override("font_color", Color.yellow)
	add_child(id_label)
	
	
func _physics_process(_delta):
	if pieces_grid.game_started:
		# Move pieces
		if parent.is_movement_frame:
			# Get state from grid
			var current_state = pieces_grid.get_current_state()
			# Pass state to brain for it to predict the next move
			var next_move = brain.process_current_state(current_state)
			# Brain gives next move for the grid to actually move the piece
			pieces_grid.control_movement(next_move)
			if parent.is_update_frame and next_move != 4:
				# Force move if it's an update frame
				pieces_grid.update_active_piece()
				
	if queued_free_pieces_grid:
		# If it lost a game but still hasn't reached the limit, create a new
		# grid
		queued_free_pieces_grid = false
		add_pieces_grid()
		
func add_pieces_grid():
	# Create grid for pieces to move with all collision logic
	pieces_grid = PiecesGrid.new(max_pieces)
	add_child(pieces_grid)
	pieces_grid.connect("increase_counter", self,
						"_on_pieces_grid_increase_counter")
	pieces_grid.connect("lose_game", self, "_on_pieces_grid_lose_game")
	pieces_grid.visible = grid_visible
	pieces_grid.next_piece_invisible = next_piece_invisible
			
func _on_pieces_grid_increase_counter():
	# Increase label on score increase
	score += 1
	if is_main:
		get_parent().get_parent().get_parent().get_node("HUD"). \
			get_node("Score").text = str(score)

func _on_pieces_grid_lose_game():
	# Check if it still has remaining games to finish, and if it does, finish
	# free current grid to make space for the next one
	no_runs += 1
	if is_main:
		get_parent().get_parent().get_parent().get_node("HUD"). \
			get_node("Game").text = str(no_runs)
	if no_runs < max_runs:
		grid_visible = pieces_grid.visible
		next_piece_invisible = pieces_grid.next_piece_invisible
		pieces_grid.queue_free()
		queued_free_pieces_grid = true
	else:
		finished_game = true
		
func make_main(x, y):
	# Make this game the main one, for main visualization
	get_parent().get_parent().get_parent().get_node("HUD"). \
		get_node("Score").text = str(score)
	get_parent().get_parent().get_parent().get_node("HUD"). \
		get_node("Game").text = str(no_runs)
	is_main = true
	position.x = x
	position.y = y
	pieces_grid.visible = true
	scale = Vector2(1, 1)
	pieces_grid.next_piece.visible = true
	pieces_grid.next_piece_invisible = false
	id_label.visible = true

func make_secondary(x, y):
	# Make this game one of the secondary ones, for secondary visualization
	is_main = false
	position.x = x
	position.y = y
	pieces_grid.visible = true
	scale = Vector2(0.333, 0.333)
	pieces_grid.next_piece.visible = false
	pieces_grid.next_piece_invisible = true
	id_label.visible = true

func make_invisible():
	# If this game is not in the top 16, make everything invisible
	is_main = false
	pieces_grid.visible = false
	pieces_grid.next_piece.visible = false
	pieces_grid.next_piece_invisible = true
	id_label.visible = false
