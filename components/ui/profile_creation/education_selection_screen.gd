extends Control

signal step_valid(valid: bool)

@onready var none_button: Button = %NoneButton
@onready var high_school_button: Button = %HighSchoolButton
@onready var some_college_button: Button = %SomeCollegeButton
@onready var bachelors_button: Button = %BachelorsButton
@onready var masters_button: Button = %MastersButton
@onready var doctorate_button: Button = %DoctorateButton

var selected_level: String = ""
var selected_student_debt: float = 0.0
var selected_credit_limit: float = 0.0

func _ready():
	for button in [
			none_button,
			high_school_button,
			some_college_button,
			bachelors_button,
			masters_button,
			doctorate_button
	]:
		button.toggle_mode = true
		button.pressed.connect(_on_option_pressed.bind(button))
	emit_signal("step_valid", false)

func _on_option_pressed(button: Button) -> void:
	# Prevent unselecting the current button
	if not button.is_pressed():
		button.set_pressed_no_signal(true)
		return

	# Deselect all other buttons
	for btn in [
		none_button,
		high_school_button,
		some_college_button,
		bachelors_button,
		masters_button,
		doctorate_button
	]:
		if btn != button:
			btn.set_pressed_no_signal(false)

	# Update selection state
	match button:
		none_button:
			selected_level = "None"
			selected_student_debt = 0.0
			selected_credit_limit = 0.0
		high_school_button:
			selected_level = "High School / GED"
			selected_student_debt = 0.0
			selected_credit_limit = 500.0
		some_college_button:
			selected_level = "Some College"
			selected_student_debt = 15000.0
			selected_credit_limit = 2000.0
		bachelors_button:
			selected_level = "Bachelor's Degree"
			selected_student_debt = 80000.0
			selected_credit_limit = 10000.0
		masters_button:
			selected_level = "Master's Degree"
			selected_student_debt = 250000.0
			selected_credit_limit = 25000.0
		doctorate_button:
			selected_level = "Doctorate"
			selected_student_debt = 1200000.0
			selected_credit_limit = 100000.0

	emit_signal("step_valid", true)



func save_data() -> void:
	var user_data = PlayerManager.user_data
	user_data["education_level"] = selected_level
	user_data["starting_student_debt"] = selected_student_debt
	user_data["starting_credit_limit"] = selected_credit_limit

	# Initialize debt resources so other systems can immediately reflect the
	# player's financial starting point.
	BillManager.debt_resources.clear()
	BillManager.debt_resources_changed.emit()

	BillManager.add_debt_resource({
			"name": "Credit Card",
			"balance": 0.0,
			"has_credit_limit": true,
			"credit_limit": selected_credit_limit,
	})

	if selected_student_debt > 0.0:
			BillManager.add_debt_resource({
					"name": "Student Loan",
					"balance": selected_student_debt,
					"has_credit_limit": false,
					"credit_limit": 0.0,
			})

	PortfolioManager.set_credit_limit(selected_credit_limit)
	PortfolioManager.set_student_loans(selected_student_debt)
