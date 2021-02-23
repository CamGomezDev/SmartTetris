# Piece
# Class that handles the logic, including rendering, for an individual piece
extends Node2D

var piece_color
var piece_shape
var piece_height
var piece_width
var pixel_size
var square_size
var width
var height
var speed = 3
var texture = load("res://assets/images/piece-white.png")
var rotation_mode

var i_position
var j_position

func _init(world_pixel_size, random_shape, random_color):
	pixel_size = world_pixel_size
	square_size = pixel_size*3
	piece_shape = random_shape
	piece_color = random_color
	piece_height = len(piece_shape)
	piece_width = len(piece_shape[0])
	width = piece_width*square_size
	height = piece_height*square_size
	rotation_mode = 0
	
func _ready():
	position.x = j_position*square_size
	position.y = i_position*square_size
	create_squares()
	
func _process(_delta):
	position.x = j_position*square_size
	position.y = i_position*square_size
	
func create_squares():
	# Creates all squares for this particular piece based on its shape
	for i in range(len(piece_shape)):
		var squares_row = piece_shape[i]
		for j in range(len(squares_row)):
			if squares_row[j]:
				var sprite = Sprite.new()
				sprite.texture = texture
				var square = Node2D.new()
				sprite.modulate = piece_color
				square.add_child(sprite)
				sprite.centered = false
				square.position.x = j * square_size
				square.position.y = i * square_size
				add_child(square)
	
func rotate_shape():
	# Rotates the matrix of the shape, and the squares corresponding to it
	rotation_mode += 1
	if rotation_mode == 4:
		rotation_mode = 0
	# Remove current squares
	for i in range(0, get_child_count()):
		get_child(i).queue_free()
	# Recalculate shape
	piece_shape = create_new_shape()
	# Recalculate variables that depend on shape
	piece_height = len(piece_shape)
	piece_width = len(piece_shape[0])
	width = piece_width*square_size
	height = piece_height*square_size
	# Load new square with updated shape
	create_squares()
	
func create_new_shape():
	# Create new shape, used for rotating the shape
	var new_shape = []
	for j in range(len(piece_shape[0])):
		var new_row = []
		for i in range(len(piece_shape)):
			new_row.append(piece_shape[len(piece_shape) - 1 - i][j])
		new_shape.append(new_row)
	return new_shape
