extends CanvasLayer

@onready var bg: ColorRect = $BG
@onready var label: Label = $Label

var _discovered_locations: Array[String] = []

func _ready() -> void:
	bg.visible = false
	label.visible = false

func show_discovery(location_name: String) -> void:
	if location_name in _discovered_locations:
		return
	_discovered_locations.append(location_name)
	var text := ""
	for loc in _discovered_locations:
		if text != "":
			text += "\n"
		text += "Local Descoberto: " + loc
	label.text = text
	bg.visible = true
	label.visible = true
