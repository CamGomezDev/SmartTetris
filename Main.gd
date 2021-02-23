extends Node
#                                                      /> Brain
# Order of relevance: Population -> Generation -> Game
#                                                      \> PiecesGrid -> Piece
var Population = load("res://classes/Population.gd")
var population = Population.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_HUD_start_game():
	add_child(population)
	population.connect("increase_gen", self, "_on_population_increase_gen")

func _on_population_increase_gen():
	$HUD/Gen.text = str(population.generation_no)
