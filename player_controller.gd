extends CharacterBody3D

@export var real_walk_speed_mps: float = 18.0
@export var real_ground_snap_m: float = 0.2

@onready var camera_controller: Node3D = $CameraController
@onready var player_mesh: MeshInstance3D = $Mesh
@onready var player_collision: CollisionShape3D = $Collision

var world_units_per_real_m: float = 1.0
var walk_speed: float
var ground_snap_length: float
var gravity: float

func _ready() -> void:
	# Player geometry calibration only; movement constants below remain unchanged.
	var player_height_units := WorldScale.meters_to_units(1.70)
	var capsule_mesh := player_mesh.mesh as CapsuleMesh
	var capsule_shape := player_collision.shape as CapsuleShape3D
	var authored_height := capsule_mesh.height
	var capsule_scale := player_height_units / authored_height
	capsule_mesh.height = player_height_units
	capsule_mesh.radius *= capsule_scale
	capsule_shape.height = player_height_units
	capsule_shape.radius *= capsule_scale
	# All metric movement values use the single canonical 45.0 m/unit source.
	world_units_per_real_m = WorldScale.meters_to_units(1.0)
	walk_speed = WorldScale.meters_to_units(real_walk_speed_mps)
	ground_snap_length = WorldScale.meters_to_units(real_ground_snap_m)
	gravity = WorldScale.meters_to_units(float(ProjectSettings.get_setting("physics/3d/default_gravity")))
	floor_snap_length = ground_snap_length

func _physics_process(delta: float) -> void:
	# Semantic actions include keyboard WASD and the normalized gamepad left stick/D-pad.
	var input_vector := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	# Preserve the existing arrow-key fallback without replacing the InputMap bindings.
	if Input.is_physical_key_pressed(KEY_LEFT):
		input_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT):
		input_vector.x += 1.0
	if Input.is_physical_key_pressed(KEY_UP):
		input_vector.y -= 1.0
	if Input.is_physical_key_pressed(KEY_DOWN):
		input_vector.y += 1.0
	if input_vector.length_squared() > 1.0:
		input_vector = input_vector.normalized()

	var camera_forward := -camera_controller.global_transform.basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right := camera_controller.global_transform.basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var move_direction := camera_right * input_vector.x + camera_forward * -input_vector.y
	var target_velocity := move_direction * walk_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, walk_speed * 8.0 * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, walk_speed * 8.0 * delta)

	if is_on_floor():
		velocity.y = -0.5 * world_units_per_real_m
	else:
		velocity.y -= gravity * delta
	move_and_slide()
