extends Control

## Displays a simple start screen and fades out when any key or mouse button is pressed.
signal continue_pressed

var _started := false

func _ready() -> void:
        set_process_input(true)

func _input(event: InputEvent) -> void:
        if _started:
                return
        if event.is_pressed():
                _started = true
                emit_signal("continue_pressed")
                var tween = create_tween()
                tween.tween_property(self, "modulate:a", 0.0, 0.5)
                tween.finished.connect(queue_free)
                set_process_input(false)
