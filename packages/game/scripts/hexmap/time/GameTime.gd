class_name GameTime
extends Resource

@export var year: int = 1850
@export var month: int = 1   # 1-12
@export var day: int = 1     # 1-31 (validated by month)
@export var hour: int = 6    # 0-23

# Optional: simple calendar rules (no leap years to keep it light unless needed)
const DAYS_IN_MONTH = [31,28,31,30,31,30,31,31,30,31,30,31]

signal time_changed(year: int, month: int, day: int, hour: int)

func _clamp_date():
	month = clamp(month, 1, 12)
	var max_day = DAYS_IN_MONTH[month - 1]
	day = clamp(day, 1, max_day)
	hour = ((hour % 24) + 24) % 24

func set_time(y: int, m: int, d: int, h: int):
	year = y
	month = m
	day = d
	hour = h
	_clamp_date()
	time_changed.emit(year, month, day, hour)

func advance_hours(hours: int):
	if hours <= 0:
		return
	hour += hours
	while hour >= 24:
		hour -= 24
		day += 1
		var max_day = DAYS_IN_MONTH[month - 1]
		if day > max_day:
			day = 1
			month += 1
			if month > 12:
				month = 1
				year += 1
	time_changed.emit(year, month, day, hour)

func get_time_string() -> String:
	var hh = str(hour)
	if hour < 10:
		hh = "0" + hh
	return "%d-%02d-%02d %s:00" % [year, month, day, hh]

func is_dawn(dawn_start: int = 5, dawn_end: int = 7) -> bool:
	return hour >= dawn_start and hour < dawn_end

func is_dusk(dusk_start: int = 18, dusk_end: int = 20) -> bool:
	return hour >= dusk_start and hour < dusk_end

func is_night(night_start: int = 20, night_end: int = 5) -> bool:
	return hour >= night_start or hour < night_end
