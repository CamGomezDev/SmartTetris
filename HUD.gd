extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal start_game

# Called when the node enters the scene tree for the first time.
func _ready():
	$NextLabel.visible = false
	$GenLabel.visible = false
	$Gen.visible = false
	$GameLabel.visible = false
	$Game.visible = false
	$LeftLabel.visible = false
	$Left.visible = false
	$ScoreLabel.visible = false
	$Score.visible = false
	
func _on_StartButton_pressed():
	$StartButton.hide()
	$Message.hide()
	$Message2.hide()
	$PiecesSprite.hide()
	
	$NextLabel.visible = true
	$GenLabel.visible = true
	$Gen.visible = true
	$LeftLabel.visible = true
	$Left.visible = true
	$GameLabel.visible = true
	$Game.visible = true
	$ScoreLabel.visible = true
	$Score.visible = true
	
	emit_signal("start_game")
