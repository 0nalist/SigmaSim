extends BaseAppUI

@onready var credit_label := %CreditLabel
@onready var credit_bar := %CreditProgressBar
@onready var credit_pay_btn := %PayCreditButton

@onready var loan_label := %StudentLoanLabel
@onready var loan_pay_btn := %PayStudentLoanButton

@onready var credit_score_label := %CreditScoreLabel

func _ready():
	app_title = "OwerView"
	emit_signal("title_updated", app_title)

	PortfolioManager.credit_updated.connect(update_credit)
	PortfolioManager.resource_changed.connect(_on_resource_changed)

	update_credit(PortfolioManager.credit_used, PortfolioManager.credit_limit)
	update_student_loans()
	update_credit_score()

func update_credit(used: float, limit: float):
	credit_label.text = "Credit Used: $%.2f / $%.2f" % [used, limit]
	credit_bar.value = (used / limit) * 100.0

func update_student_loans():
	var loans := PortfolioManager.get_student_loans()
	loan_label.text = "Student Loans: $%.2f" % loans

func _on_resource_changed(name: String, value: float):
	if name == "student_loans":
		update_student_loans()
	elif name == "debt":
		update_credit_score()

func update_credit_score():
	var score = PortfolioManager.get_credit_score()
	credit_score_label.text = "Credit Score: %d" % score

func _on_PayCreditButton_pressed():
	var amount := PortfolioManager.credit_used
	PortfolioManager.pay_down_credit(amount)

func _on_PayLoanButton_pressed():
	var amount := PortfolioManager.get_student_loans()
	if PortfolioManager.pay_with_cash(amount):
		PortfolioManager.set_student_loans(0.0)
