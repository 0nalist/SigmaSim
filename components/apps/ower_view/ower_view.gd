extends BaseAppUI

@onready var credit_label := %CreditLabel
@onready var credit_interest_label: Label = %CreditInterestLabel
@onready var credit_bar := %CreditProgressBar
@onready var credit_pay_btn := %PayCreditButton
@onready var credit_slider := %CreditSlider
@onready var credit_slider_label := %CreditSliderLabel

@onready var loan_label := %StudentLoanLabel
@onready var loan_pay_btn := %PayStudentLoanButton
@onready var loan_slider := %LoanSlider
@onready var loan_slider_label := %LoanSliderLabel

@onready var credit_score_label := %CreditScoreLabel

func _ready():
	app_title = "OwerView"
	emit_signal("title_updated", app_title)

	PortfolioManager.credit_updated.connect(update_credit)
	PortfolioManager.resource_changed.connect(_on_resource_changed)
	PortfolioManager.cash_updated.connect(_on_cash_updated)

	credit_slider.value_changed.connect(_on_credit_slider_changed)
	loan_slider.value_changed.connect(_on_loan_slider_changed)

	update_credit(PortfolioManager.credit_used, PortfolioManager.credit_limit)
	update_student_loans()
	update_credit_score()
	update_credit_interest_label()
	update_sliders()

func update_credit(used: float, limit: float):
	credit_label.text = "Credit Used: $%.2f / $%.2f" % [used, limit]
	credit_bar.value = (used / limit) * 100.0
	update_credit_interest_label()
	update_sliders()

func update_student_loans():
	var loans := PortfolioManager.get_student_loans()
	loan_label.text = "Student Loans: $%.2f" % loans
	update_sliders()

func update_credit_interest_label():
	credit_interest_label.text = "Interest Rate: %.1f%%" % (PortfolioManager.credit_interest_rate * 100.0)


func update_credit_score():
	var score = PortfolioManager.get_credit_score()
	credit_score_label.text = "%d" % score

func _on_resource_changed(name: String, value: float):
	if name == "student_loans":
		update_student_loans()
	elif name == "debt":
		update_credit_score()

func _on_cash_updated(_cash: float):
	update_sliders()

func update_sliders():
	var cash := PortfolioManager.cash

	# Credit Slider
	var credit_max = min(PortfolioManager.credit_used, cash)
	credit_slider.max_value = credit_max
	if credit_slider.value > credit_max:
		credit_slider.value = credit_max
	credit_slider_label.text = "$%.2f" % credit_slider.value

	# Loan Slider
	var loan_max = min(PortfolioManager.get_student_loans(), cash)
	loan_slider.max_value = loan_max
	if loan_slider.value > loan_max:
		loan_slider.value = loan_max
	loan_slider_label.text = "$%.2f" % loan_slider.value

func _on_credit_slider_changed(value: float):
	credit_slider_label.text = "$%.2f" % value

func _on_loan_slider_changed(value: float):
	loan_slider_label.text = "$%.2f" % value


func _on_pay_credit_button_pressed() -> void:
	var amount = credit_slider.value
	PortfolioManager.pay_down_credit(amount)
	update_sliders()


func _on_pay_student_loan_button_pressed() -> void:
	var amount = loan_slider.value
	if PortfolioManager.pay_with_cash(amount):
		var new_amt = PortfolioManager.get_student_loans() - amount
		PortfolioManager.set_student_loans(max(new_amt, 0.0))
	update_sliders()
