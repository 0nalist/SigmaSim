extends Control

@export var scroll_speed: float = 50.0
@export var line_width: int = 50
@export var fade_time: float = 2.0

const CREDITS_TEXT := """
Placeholder Studio

SIGMA SIM

Created by Sam Payne



Game Director: Sam Payne
Technical Director: Sam Payne
Art Director: Sam Payne
Audio Director: TBD



Executive Producer: Sam Payne



Lead Designer: Sam Payne
Lead Programmer: Sam Payne
Lead Artist: Sam Payne
Lead Writer: Sam Payne




Quality Assurance

Lead: Sam Payne
Testers: [YOUR NAME COULD GO HERE]



Fonts

ChicagoFLF
by Robin Casady (Casady & Greene)
Public Domain License



Luckiest Guy Font
by Astigmatic One Eye Typographic Institute
Apache License, Version 2.0




Monoton Font
by Vernon Adams
Public Domain License




Made in the Godot Game Engine
godotengine.org
"""

@onready var container: VBoxContainer = $VBoxContainer
@onready var fade_rect: ColorRect = $FadeRect

func _ready() -> void:
	_populate_credits()
	await get_tree().process_frame
	container.position.y = size.y
	var distance := container.size.y + size.y
	var duration := distance / scroll_speed
	var tween := get_tree().create_tween()
	tween.tween_property(container, "position:y", -container.size.y, duration)
	tween.finished.connect(_on_scroll_finished)

func _populate_credits() -> void:
	for raw_line in CREDITS_TEXT.strip_edges(true, true).split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty():
			var spacer := Control.new()
			spacer.custom_minimum_size.y = 20
			container.add_child(spacer)
			continue
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if line.contains(":"):
			var parts := line.split(":", false, 2)
			label.text = _dot_line(parts[0].strip_edges(), parts[1].strip_edges(), line_width)
		else:
			label.text = line
		container.add_child(label)

func _dot_line(left: String, right: String, width: int) -> String:
	var dots = max(width - left.length() - right.length(), 2)
	return left + ".".repeat(dots) + right

func _on_scroll_finished() -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_time)
	tween.finished.connect(queue_free)
