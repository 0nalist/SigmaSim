extends Control
class_name GameOverPopup

signal delete_save_pressed
signal reload_save_pressed
signal continue_pressed

@export var reason: String = ""

@onready var header_label: Label = %HeaderLabel
@onready var reason_label := %ReasonLabel

@onready var delete_button := %DeleteButton
@onready var reload_button := %ReloadButton
@onready var continue_button := %ContinueButton

func _ready():
        header_label.text = " GAME OVER "
        reason_label.text = reason

       # Disable reloading if no valid save slot is active
       reload_button.disabled = SaveManager.current_slot_id <= 0


        delete_button.pressed.connect(func(): emit_signal("delete_save_pressed"))
        reload_button.pressed.connect(func(): emit_signal("reload_save_pressed"))
        continue_button.pressed.connect(func(): emit_signal("continue_pressed"))
	
	## Spawn Siggy to popup and taunt the player
	
