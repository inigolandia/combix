extends CanvasLayer

@onready var bg: ColorRect = $BG
@onready var label: Label = $Label

var _discovered := false

func _ready() -> void:
	bg.visible = false
	label.visible = false

func show_discovery(location_name: String) -> void:
	_discovered = true
	label.text = "Local Descoberto: " + location_name
	bg.visible = true
	label.visible = true
