class_name SaveService
extends RefCounted
const VERSION = 1
var path: String
var data: Dictionary
var warning = ""

func _init(save_path: String = "user://echofold.json") -> void:
	path = save_path
	data = defaults()
	load_save()

static func defaults() -> Dictionary:
	return {"version": VERSION, "completed": {}, "daily": {}, "current": 0, "active": {}, "settings": {"language": "en", "music": true, "sfx": true, "haptics": true, "reduced_motion": false, "effects": 0.65}, "stats": {"folds": 0, "solves": 0, "hints": 0, "seconds": 0.0}}

func load_save() -> void:
	for candidate in [path, path + ".bak", path + ".tmp"]:
		if not FileAccess.file_exists(candidate): continue
		var parser = JSON.new()
		var decoded = null
		if parser.parse(FileAccess.get_file_as_string(candidate)) == OK: decoded = parser.data
		if not decoded is Dictionary:
			warning = "corrupt_save"
			continue
		if decoded.get("version", 0) != VERSION:
			warning = "future_save"
			continue
		for field in ["completed", "daily", "settings", "stats", "active"]:
			if decoded.get(field) is Dictionary:
				for key in decoded[field]:
					if field in ["settings", "stats"]:
						if data[field].has(key) and typeof(decoded[field][key]) == typeof(data[field][key]):
							data[field][key] = decoded[field][key]
					else:
						data[field][key] = decoded[field][key]
		if decoded.get("current") is float or decoded.get("current") is int:
			data.current = clampi(int(decoded.current), 0, 59)
		# JSON numbers decode as float; accept finite nonnegative statistics.
		for key in data.stats:
			var value = decoded.get("stats", {}).get(key, 0)
			data.stats[key] = maxf(0, float(value)) if (value is float or value is int) and is_finite(float(value)) else 0
		data.settings.effects = clampf(float(data.settings.effects), 0, 1)
		for field in ["completed", "daily"]:
			var clean = {}
			for key in data[field]:
				var record = data[field][key]
				if record is Dictionary and record.get("best") is float and record.get("stars") is float:
					if record.best >= 0 and record.stars >= 1 and record.stars <= 3:
						clean[key] = {"best": int(record.best), "stars": int(record.stars)}
			data[field] = clean
		return

func write() -> bool:
	# Never replace an unsupported future-version save.
	if warning == "future_save": return false
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		var current = JSON.parse_string(FileAccess.get_file_as_string(path))
		if current is Dictionary and current.get("version") == VERSION:
			var backup = FileAccess.open(path + ".bak", FileAccess.WRITE)
			if backup == null: return false
			backup.store_string(JSON.stringify(current))
			backup.flush()
			backup.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path)) == OK

func unlocked(index: int) -> bool:
	return index == 0 or data.completed.has(str(index - 1))

func award(index: int, moves: int, par: int, daily_id: String = "") -> int:
	var stars = 3 if moves <= par else (2 if moves <= par + 2 else 1)
	var records: Dictionary = data.completed if daily_id.is_empty() else data.daily
	var key = str(index) if daily_id.is_empty() else daily_id
	var previous = records.get(key, {"best": 9999, "stars": 0})
	records[key] = {"best": mini(moves, previous.best), "stars": maxi(stars, previous.stars)}
	data.stats.solves += 1
	if daily_id.is_empty(): data.current = mini(index + 1, 59)
	data.active = {}
	write()
	return stars
