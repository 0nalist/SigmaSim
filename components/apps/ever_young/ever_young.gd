extends Pane
class_name EverYoung

@onready var nav_bar: PaneNavBar = %PaneNavBar
@onready var summary_view: Control = %SummaryView
@onready var procedures_view: Control = %ProceduresView
@onready var rx_view: Control = %RxView

func _ready() -> void:
	nav_bar.add_nav_button("Summary", "Summary")
	nav_bar.add_nav_button("Procedures", "Procedures")
	nav_bar.add_nav_button("Rx", "Rx")
	nav_bar.tab_selected.connect(func(tab_id: String): _activate_tab(tab_id))
	nav_bar.set_active("Summary")

func _activate_tab(tab_id: String) -> void:
	summary_view.visible = tab_id == "Summary"
	procedures_view.visible = tab_id == "Procedures"
	rx_view.visible = tab_id == "Rx"
