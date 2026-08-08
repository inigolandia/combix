extends Area3D

@export var location_name: String = "Local Desconhecido"
@export var hud_path: NodePath

var _discovered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	if _discovered:
		set_physics_process(false)
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_discovered = true
			var hud = get_node(hud_path)
			if hud and hud.has_method("show_discovery"):
				hud.show_discovery(location_name)
			set_physics_process(false)
			break

func _on_body_entered(body: Node3D) -> void:
	if _discovered:
		return
	if body.is_in_group("player"):
		_discovered = true
		var hud = get_node(hud_path)
		if hud and hud.has_method("show_discovery"):
			hud.show_discovery(location_name)
