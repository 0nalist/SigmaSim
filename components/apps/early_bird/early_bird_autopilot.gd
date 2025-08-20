extends Node

# Reference to the player node.
@onready var player: EarlyBirdPlayer = %EarlyBirdPlayer
@onready var pipe_manager: EarlyBirdPipeManager = %PipeManager

var enabled: bool = false

func _process(delta: float) -> void:
	if not enabled or not player or not player.is_alive:
		return
	if not pipe_manager:
		printerr("Autopilot cannot find pipe manager")
		return

        var pipes = pipe_manager.get_active_pipe_pairs()
        if pipes.is_empty():
                if player.position.y > 300:
                        player.flap()
                return

        # Find the first pipe ahead of the player
        var next_pipe = null
        for pipe in pipes:
                if pipe.position.x > player.position.x - 40: # Adjust magic number for fine tuning
                        next_pipe = pipe
                        break

        if player.position.y > 550:
                        player.flap()

        if next_pipe:
                var target_y = next_pipe.get_gap_center_y() #- 51 # Adjust magic number for fine tuning
                if player.position.y > target_y:
                        player.flap()
			
        #print(player.position)
