extends Panel

@onready var timer: Timer = $TickerTimer
@onready var text_label: RichTextLabel = $RichTextLabel

var current_template: String = ""

var ticker_entries: Array = [
	{
		"text": "You currently have {cash} in your wallet.",
		"condition": func() -> bool: return PortfolioManager.cash > 0
	},
	{
		"text": "Your crypto portfolio is worth {crypto_total}",
		"condition": func() -> bool: return PortfolioManager.get_crypto_total() > 0
	},
	{
		"text": "It is {day}, do you know what you're doing with your life?",
		"condition": null
	},
	{
		"text": "Did you know that pets have souls?",
		"condition": null
	},
	{
		"text": "No news is good news?         No!     News is good news.",
		"condition": null
	},
	{
		"text": "Nine out of ten dentists regret loving me",
		"condition": null
	},
]

var ticker_variables := {
	"cash": func(): return "$%.2f" % PortfolioManager.cash,
	"crypto_total": func(): return "$%.2f" % PortfolioManager.get_crypto_total(),
	"day": func(): return "Day %s" % TimeManager.get_formatted_date(),
	"time": func(): return TimeManager.get_formatted_time(),
}

var scroll_tween: Tween = null
var current_text: String = ""

func _ready():
	timer.wait_time = 4.0
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	_show_next_ticker()


func _process(_delta):
	if current_template != "":
		text_label.text = format_ticker_text(current_template)


func _on_timer_timeout():
	print("ticker timeout")
	_show_next_ticker()

func _show_next_ticker():
	current_template = get_next_ticker_template()
	text_label.text = format_ticker_text(current_template)
	text_label.visible_characters = -1

	text_label.position.x = size.x
	text_label.position.y = (size.y - text_label.size.y) / 2.0

	var distance = text_label.position.x + text_label.size.x
	var duration = max(3.5, distance / 80.0)

	if scroll_tween:
		scroll_tween.kill()
	scroll_tween = create_tween()
	scroll_tween.tween_property(text_label, "position:x", -text_label.size.x, duration).set_trans(Tween.TRANS_LINEAR)
	scroll_tween.finished.connect(func():
		timer.start()
	)


func get_next_ticker_template() -> String:
	var candidates := []
	for entry in ticker_entries:
		if entry.condition == null or entry.condition.call():
			candidates.append(entry)
	if candidates.is_empty():
		return "No news is good news."
	var selected = candidates.pick_random()
	return selected.text

func format_ticker_text(text: String) -> String:
	for key in ticker_variables.keys():
		var token = "{" + key + "}"
		if text.find(token) != -1:
			text = text.replace(token, ticker_variables[key].call())
	return text
