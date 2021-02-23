# Brain
# Analyses current game state and provides best move using params
var previous_piece_index
var previous_move
var a
var b
var c
var d
var score
var current_selected_move

var possible_moves_scored
var highest_score

func _init(a_in, b_in, c_in, d_in):
	# Initialize brain with params
	self.a = a_in
	self.b = b_in
	self.c = c_in
	self.d = d_in
	
func possible_mutate(mutation_factor):
	# Possibly mutate when creating the brain for a new generation.
	# There's a mutation_factor probability of it mutating any of its params.
	var full_prob = 10000
	var attempts_prob = mutation_factor * full_prob
	var max_possible_mutation = 0.2
	randomize()
	if randi() % full_prob < attempts_prob:
		randomize()
		var switch = randi() % 4
		if switch == 0:
			randomize()
			a += randf() * 2 * max_possible_mutation - max_possible_mutation
		elif switch == 1:
			randomize()
			b += randf() * 2 * max_possible_mutation - max_possible_mutation
		elif switch == 2:
			randomize()
			c += randf() * 2 * max_possible_mutation - max_possible_mutation
		elif switch == 3:
			randomize()
			d += randf() * 2 * max_possible_mutation - max_possible_mutation

func process_current_state(current_state):
	# Recieives current state to predict best move
	var new_move
	# Check if there's a new piece in the board
	if previous_piece_index != current_state.shape_index:
		# Analyze all possible moves and score them
		possible_moves_scored = score_all_possible_moves(current_state)
		# Pick best one
		highest_score = possible_moves_scored[0]["score"]
		current_selected_move = possible_moves_scored[0]
		for move in possible_moves_scored:
			if move["score"] > highest_score:
				highest_score = move["score"]
				# Use that as the next general trajectory
				current_selected_move = move
	# Pick move in movement frame from current trajectory
	new_move = select_move_from_current_selected_move(current_state)
	previous_piece_index = current_state.shape_index
	return new_move

func score_all_possible_moves(current_state):
	# Analyse all possible moves
	var possible_moves = []
	# First check all possible rotations
	for rotation_mode in range(4):
		# Rotate to this rotation
		var rotated_shape = rotate_shape(current_state["shape"], rotation_mode)
		# Now check all possible positions for this rotation
		for j_position in range(0, current_state["grid"][0].size() - \
								rotated_shape[0].size() + 1):
			var i_position = current_state["shape_i"]
			while(!blocks_below(rotated_shape, i_position, j_position,
							   current_state["grid"])):
				# Make the block go down until it stops
				i_position += 1
			# Create possible grid with this new position
			var possible_final_state = create_final_state(
				current_state["grid"], rotated_shape, i_position, j_position)
			# Score this position
			var possible_final_state_score = score_state(possible_final_state)
			possible_moves.append({ "rotation_mode": rotation_mode, 
									"i": i_position, "j": j_position,
									"score": possible_final_state_score })
	return possible_moves

func rotate_shape(shape, rotation_mode):
	# Makes shape rotate
	var old_shape = shape
	var new_shape = shape
	for _rotation in range(rotation_mode):
		new_shape = []
		for j in range(len(old_shape[0])):
			var new_row = []
			for i in range(len(old_shape)):
				new_row.append(old_shape[len(old_shape) - 1 - i][j])
			new_shape.append(new_row)
		old_shape = new_shape
	
	return new_shape
			
func blocks_below(shape, i_position, j_position, grid):
	# Check if there are blocks below or if it can keep going down
	
	# First check if it reached the end of the world
	if i_position + shape.size() + 1 > grid.size():
		return true
		
	# Now check collision with bottom possible pieces
	for j in range(len(shape[0])):
		var column_bottom_piece = 0
		for i in range(len(shape)):
			if shape[i][j]:
				column_bottom_piece = i
		# Check square below bottom piece square of the column
		if grid[i_position + column_bottom_piece + 1][j_position + j]:
			return true
	
	return false
			
func create_final_state(grid, shape, i_position, j_position):
	# Add new possible piece position to grid to score this state
	var new_full_grid = []
	for i in range(len(grid)):
		var new_row = []
		for j in range(len(grid[i])):
			if i >= i_position and i < i_position + len(shape) and \
			   j >= j_position and j < j_position + len(shape[0]) and \
			   shape[i - i_position][j - j_position]:
				new_row.append(1)
			else:
				new_row.append(grid[i][j])
		new_full_grid.append(new_row)
				
	return new_full_grid
	
func score_state(grid):
	# Use formula to score this possible grid
	var aggregate_height = aggregate_height(grid)
	var complete_lines = complete_lines(grid)
	var holes = holes(grid)
	var bumpiness = bumpiness(grid)
	var state_score = a * aggregate_height + b * complete_lines + \
					  c * holes + d * bumpiness
	return state_score
	
func aggregate_height(grid):
	# Calculate aggregate height
	var aggregate_height = 0
	for j in range(len(grid[0])):
		var found_first_one = false
		for i in range(len(grid)):
			if grid[i][j] and !found_first_one:
				found_first_one = true
				aggregate_height += len(grid) - i
	return aggregate_height
	
func complete_lines(grid):
	# Calculate number complete lines
	var complete_lines = 0
	for i in range(len(grid)):
		var full_row = true
		for j in range(len(grid[i])):
			if grid[i][j] == 0:
				full_row = false
		if full_row:
			complete_lines += 1
	return complete_lines

func holes(grid):
	# Calculate number of holes
	var holes = 0
	for j in range(len(grid[0])):
		var found_first_one = false
		for i in range(len(grid)):
			if grid[i][j] and !found_first_one:
				found_first_one = true
			if found_first_one:
				if grid[i][j] == 0:
					holes += 1
	return holes
	
func bumpiness(grid):
	# Calculate bumpiness
	var bumpiness = 0
	var previous_height
	for j in range(len(grid[0])):
		var found_first_one = false
		for i in range(len(grid)):
			if grid[i][j] and !found_first_one:
				found_first_one = true
				var height = len(grid) - i
				if j > 0:
					bumpiness += abs(height - previous_height)
				previous_height = height
		if !found_first_one:
			if j > 0:
				bumpiness += previous_height
			previous_height = 0
	return bumpiness
	
func select_move_from_current_selected_move(state):
	# Pick next move for piece to go along current trajectory
	# If it can rotate and it's required for the trajectory, then rotate
	if state["shape_rotation"] != current_selected_move["rotation_mode"]:
		if shape_can_rotate(state["shape"], state["grid"],
							state["shape_i"], state["shape_j"]):
			return 1
	# Else, if it's not on top of where the next move is, then go that way
	if state["shape_j"] < current_selected_move["j"]:
		return 2
	if state["shape_j"] > current_selected_move["j"]:
		return 3
	return 4
	
func shape_can_rotate(shape, grid, i_position, j_position):
	# Check possible collisions for piece to rotate
	var possible_new_shape = rotate_shape(shape, 1)
	for i in range(len(possible_new_shape)):
		for j in range(len(possible_new_shape[i])):
			if i + i_position >= len(grid) or j + j_position >= len(grid[0]) or\
			   (possible_new_shape[i][j] and \
				grid[i + i_position][j + j_position]):
				return false
	return true








# Useless holes code that took me 2 fucking hours to write to realize it's 
# not how you're supposed to calculate the number of holes
func holes_legacy(grid):
	var holes = 0
	var grid_for_holes = []
	for i in range(len(grid)):
		var row = []
		for _j in range(len(grid[i])):
			row.append(1)
		grid_for_holes.append(row)
		
	var squares_to_check = [{ "i": 0, "j": 0 }]
	while(len(squares_to_check) > 0):
		var new_squares_to_check = []
		for square in squares_to_check:
			grid_for_holes[square["i"]][square["j"]] = 0
			var squares_around = []
			# Check top
			if square["i"] > 0:
				if grid[square["i"] - 1][square["j"]] == 0 and \
				   grid_for_holes[square["i"] - 1][square["j"]] != 0:
					squares_around.append({"i": square["i"] - 1, 
										   "j": square["j"]})
			# Check right
			if square["j"] < 9:
				if grid[square["i"]][square["j"] + 1] == 0 and \
				   grid_for_holes[square["i"]][square["j"] + 1] != 0:
					squares_around.append({"i": square["i"],
										   "j": square["j"] + 1})
			# Check bottom
			if square["i"] < 19:
				if grid[square["i"] + 1][square["j"]] == 0 and \
				   grid_for_holes[square["i"] + 1][square["j"]] != 0:
					squares_around.append({"i": square["i"] + 1,
										   "j": square["j"]})
			# Check left
			if square["j"] > 0:
				if grid[square["i"]][square["j"] - 1] == 0 and \
				   grid_for_holes[square["i"]][square["j"] - 1] != 0:
					squares_around.append({"i": square["i"],
										   "j": square["j"] - 1})
			for square_around in squares_around:
				var square_around_in_new_squares = false
				for new_square in new_squares_to_check:
					if new_square["i"] == square_around["i"] and \
					   new_square["j"] == square_around["j"]:
						square_around_in_new_squares = true
				
				if !square_around_in_new_squares:
					new_squares_to_check.append(square_around)
		
		squares_to_check = new_squares_to_check
		
	for i in range(len(grid)):
		for j in range(len(grid[i])):
			if grid[i][j] == 0 and grid_for_holes[i][j] == 1:
				holes += 1
				
	return holes
