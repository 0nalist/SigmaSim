extends Node
#class_name NumberFormatter

const SHORT_UNITS = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
const LONG_UNITS = [
	"", "Thousand", "Million", "Billion", "Trillion",
	"Quadrillion", "Quintillion", "Sextillion", "Septillion", "Octillion"
]

# Add commas: 1,234,567.89
static func format_commas(number: float, decimals: int = 2) -> String:
	var parts = str("%.*f" % [decimals, number]).split(".")
	var int_part = parts[0]
	var sign = ""
	if int_part.begins_with("-"):
		sign = "-"
		int_part = int_part.substr(1)
	var out = ""
	while int_part.length() > 3:
		out = "," + int_part.right(3) + out
		int_part = int_part.left(int_part.length() - 3)
	out = int_part + out
	if parts.size() > 1 and decimals > 0:
		return sign + out + "." + parts[1]
	return sign + out

# Short text: 4.2M, 9.8T
static func format_short(number: float, decimals: int = 2) -> String:
	var n = abs(number)
	var sign = "-" if number < 0 else ""
	if n < 1_000:
		return "%s%.*f" % [sign, decimals, n]
	var idx = 0
	while n >= 1_000 and idx < SHORT_UNITS.size() - 1:
		n /= 1_000.0
		idx += 1
	return "%s%.*f%s" % [sign, decimals, n, SHORT_UNITS[idx]]

# Long text: 2.1 Million
static func format_long(number: float, decimals: int = 2) -> String:
	var n = abs(number)
	var sign = "-" if number < 0 else ""
	if n < 1_000:
		return "%s%.*f" % [sign, decimals, n]
	var idx = 0
	while n >= 1_000 and idx < LONG_UNITS.size() - 1:
		n /= 1_000.0
		idx += 1
	return "%s%.*f %s" % [sign, decimals, n, LONG_UNITS[idx]]

# Scientific: 6.02e23
static func format_sci(number: float, decimals: int = 2) -> String:
	if number == 0:
		return "0"
	var sign = "-" if number < 0 else ""
	var n = abs(number)
	var exponent = int(floor(log(n) / log(10)))
	var mantissa = n / pow(10, exponent)
	return "%s%.*fe%d" % [sign, decimals, mantissa, exponent]

# Main interface
static func format_number(number: float, style: String = "commas", decimals: int = 2) -> String:
	match style:
		"commas":
			return format_commas(number, decimals)
		"short":
			return format_short(number, decimals)
		"long":
			return format_long(number, decimals)
		"sci", "scientific":
			return format_sci(number, decimals)
		_:
			return str(number)
