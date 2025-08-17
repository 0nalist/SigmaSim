extends Pane

@onready var tab_bar = %TabBar

@onready var resumes_list: VBoxContainer = %ResumesList



func _ready():
	generate_and_show_npcs(5)

func generate_and_show_npcs(n: int):
	for child in resumes_list.get_children():
		child.queue_free()
	for i in range(n):
		var npc = NPCFactory.create_npc(i)
		var label = Label.new()
		label.text = npc.full_name
		resumes_list.add_child(label)


func get_drag_handle() -> Control:
	return tab_bar
