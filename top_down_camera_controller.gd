extends Node3D
# Third-person orbit camera: this pivot follows the Player automatically.

# Distances are in the compressed Sector 1 world units: close local view and map view.
@export var min_distance: float = 0.12
@export var max_distance: float = 20.0
@export var zoom_step: float = 0.5
@export var zoom_smoothing_speed: float = 10.0
@export var orbit_sensitivity: float = 0.012
@export var gamepad_orbit_speed: float = 2.4
@export var min_pitch_degrees: float = -35.0
@export var max_pitch_degrees: float = 25.0
@export var local_view_distance: float = 0.35
@export var map_view_distance: float = 20.0

@onready var spring_arm: SpringArm3D = $SpringArm3D

var _target_distance: float
var _target_pitch: float
var _orbiting := false

func _ready() -> void:
	_target_distance = spring_arm.spring_length
	_target_pitch = spring_arm.rotation.x

func _process(delta: float) -> void:
	# The right stick feeds the same semantic orbit actions as keyboard/mouse input.
	var camera_input := Input.get_vector(&"camera_left", &"camera_right", &"camera_up", &"camera_down")
	if camera_input.length_squared() > 0.0:
		rotation.y -= camera_input.x * gamepad_orbit_speed * delta
		_target_pitch = clampf(
			_target_pitch - camera_input.y * gamepad_orbit_speed * delta,
			deg_to_rad(min_pitch_degrees),
			deg_to_rad(max_pitch_degrees)
		)
	if Input.is_action_just_pressed(&"zoom_out"):
		_zoom_by(zoom_step)
	if Input.is_action_just_pressed(&"zoom_in"):
		_zoom_by(-zoom_step)

	spring_arm.spring_length = lerpf(
		spring_arm.spring_length,
		_target_distance,
		1.0 - exp(-zoom_smoothing_speed * delta)
	)
	spring_arm.rotation.x = lerpf(
		spring_arm.rotation.x,
		_target_pitch,
		1.0 - exp(-zoom_smoothing_speed * delta)
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_set_orbiting(false)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_set_orbiting(event.pressed)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_by(-zoom_step)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_by(zoom_step)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			_zoom_by(-zoom_step)
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			_zoom_by(zoom_step)
	elif event is InputEventMouseMotion and _orbiting:
		rotation.y -= event.relative.x * orbit_sensitivity
		_target_pitch = clampf(
			_target_pitch - event.relative.y * orbit_sensitivity,
			deg_to_rad(min_pitch_degrees),
			deg_to_rad(max_pitch_degrees)
		)

func _set_orbiting(active: bool) -> void:
	_orbiting = active
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and _orbiting:
		_set_orbiting(false)

func _zoom_by(amount: float) -> void:
	_target_distance = clampf(_target_distance + amount, min_distance, max_distance)
