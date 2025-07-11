extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# In your main game scene script, to display the user's email:
	%Label.text = "Welcome, " + str(Global.user_email)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
