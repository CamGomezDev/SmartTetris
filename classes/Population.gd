# Population
# Class that creates generations, games and all of the crossover code.
extends Node

var pop_size = 800 # Number of individuals
var max_pieces = 500 # Maximum number of pieces a single game can have
var trials_per_game = 10 # Maximum number of times a single game can die
var first_group_fraction = 0.3 # Percentage of brains that are created from good brains in new generation
var pool_for_first_group_fraction = 0.1 # Percentage for pools used to pick best two to create new brains
var mutation_factor = 0.07 # Probability of mutation for a brain
var generation_no = 0
var Generation = load("res://classes/Generation.gd")
var Brain = load("res://classes/Brain.gd")
var generation
var queued_free_generation = false
var last_brains
var new_brains

signal increase_gen


func _ready():
	# The first generation is created
	generation = Generation.new(first_brains(), max_pieces, trials_per_game)
	add_child(generation)
	# Signal for generation change
	generation.connect("finished", self, "_on_generation_finished")
	
func _physics_process(_delta):
	if queued_free_generation:
		# A generation changed, so a new one is created with new brains
		queued_free_generation = false
		generation = Generation.new(new_brains, max_pieces, trials_per_game)
		add_child(generation)
		generation.connect("finished", self, "_on_generation_finished")
		

func first_brains():
	# First random brains. Uncomment lines to create brains with specific params
	# This creates the random params (DNA) for each new brain
	var brains = []
#	var possible_as = [-0.619, -0.469, -0.510]
#	var possible_bs = [0.315, 0.443, 0.761]
#	var possible_cs = [-0.647, -0.520, -0.357]
#	var possible_ds = [-0.247, -0.158, -0.184]
	# Unco
	for _i in range(pop_size):
		randomize()
		var a = (randf() * 2) - 1
		randomize()
		var b = (randf() * 2) - 1
		randomize()
		var c = (randf() * 2) - 1
		randomize()
		var d = (randf() * 2) - 1
		randomize()
#		var picked_brain = randi() % possible_as.size()
#		var a = possible_as[picked_brain]
#		var b = possible_bs[picked_brain]
#		var c = possible_cs[picked_brain]
#		var d = possible_ds[picked_brain]
		brains.append(Brain.new(a, b, c, d))
	
	return brains

func _on_generation_finished():
	# Generation change
	# First it gets the best brain to print is parameters
	var best_game = generation.get_children()[0]
	for game in generation.get_children():
		if game.score > best_game.score:
			best_game = game
	print("Result of generation " + str(generation_no))
	print("Best game: " + str(best_game.id))
	print("Params -> a: " + str(best_game.brain.a) + \
				  ", b: " + str(best_game.brain.b) + \
				  ", c: " + str(best_game.brain.c) + \
				  ", d: " + str(best_game.brain.d))
	print("Score -> " + str(best_game.score))
	generation_no += 1
	emit_signal("increase_gen")
	# Then, the finished generation's brains are copied to be combined
	last_brains = generation.copy_brains()
	generation.queue_free()
	queued_free_generation = true
	new_brains = combine_new_brains_from_last_gen()
	
	
func combine_new_brains_from_last_gen():
	new_brains = []
	var brains_indexes = []
	# First 30% of brains are made...
	for _i in range(floor(first_group_fraction * pop_size)):
		var brains_for_new_brain = []
		var brains_indexes_selected = []
		# By picking the two best ones from a random 10% pool and combining
		# them
		for _j in range(floor(pool_for_first_group_fraction * pop_size)):
			randomize()
			var new_index = randi() % pop_size
			while new_index in brains_indexes:
				randomize()
				new_index = randi() % pop_size
			brains_indexes_selected.append(new_index)
			brains_for_new_brain.append(last_brains[new_index])
		
		brains_for_new_brain.sort_custom(CustomSorterBrains, "sort")
		new_brains.append(brain_crossover(
			brains_for_new_brain[brains_for_new_brain.size() - 2], 
			brains_for_new_brain[brains_for_new_brain.size() - 1]))
			
	last_brains.sort_custom(CustomSorterBrains, "sort")
	# The worst 30% of the finished generation is dropped to be replaced
	# by the recently made 30%, and that full combo are the new brains.
	for i in range(0, pop_size - floor(first_group_fraction * pop_size)):
		new_brains.append(Brain.new(last_brains[i].a, last_brains[i].b, 
			last_brains[i].c, last_brains[i].d))
			
	return new_brains
	
	
func brain_crossover(first_brain, second_brain):
	# Combines brains giving priority to best one, while at the same time
	# it's normalizing.
	var new_a = first_brain.a * first_brain.score + \
		second_brain.a * second_brain.score
	var new_b = first_brain.b * first_brain.score + \
		second_brain.b * second_brain.score
	var new_c = first_brain.c * first_brain.score + \
		second_brain.c * second_brain.score
	var new_d = first_brain.d * first_brain.score + \
		second_brain.d * second_brain.score
	if (first_brain.score + second_brain.score) != 0:
		new_a = new_a / (first_brain.score + second_brain.score)
		new_b = new_b / (first_brain.score + second_brain.score)
		new_c = new_c / (first_brain.score + second_brain.score)
		new_d = new_d / (first_brain.score + second_brain.score)
	var new_brain = Brain.new(new_a, new_b, new_c, new_d)
	new_brain.possible_mutate(mutation_factor)
	return new_brain

	
class CustomSorterBrains:
	static func sort(a, b):
		if a.score < b.score:
			return true
		return false
