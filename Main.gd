extends Node

const RAGDOLL_SCENE := preload("res://Ragdoll.tscn")

@onready var _dolls: Node2D = %Dolls
@onready var _dolls_box: Panel = %DollsBox

var _preview: Control = null


func _ready() -> void:
	_dolls_box.set_drag_forwarding(_get_doll_drag_data, Callable(), Callable())


func _process(_delta: float) -> void:
	_update_preview_doll()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ek := event as InputEventKey
		if ek.keycode == KEY_ENTER && not ek.pressed:
			var ragdoll := RAGDOLL_SCENE.instantiate()
			ragdoll.global_position.x = randi_range(200, 960)
			ragdoll.global_position.y = randi_range(180, 220)
			ragdoll.rotation_degrees = randf_range(-180, 180)
			_dolls.add_child(ragdoll)


func _update_preview_doll() -> void:
	if is_instance_valid(_preview) && _preview.get_child_count() > 0:
		var ragdoll: Node2D = _preview.get_child(0)
		var skeleton: Skeleton2D = ragdoll.get_node("Skeleton")
		var phead: PhysicalBone2D = skeleton.get_node("PBody/PNeck/PHead")

		phead.global_position = _preview.global_position


func _get_doll_drag_data(_at_position: Vector2) -> Variant:
	var preview := Control.new()
	var ragdoll := RAGDOLL_SCENE.instantiate()
	ragdoll.top_level = true
	ragdoll.global_position = get_viewport().get_mouse_position() + Vector2(0, 120)
	preview.add_child(ragdoll)

	_dolls_box.set_drag_preview(preview)
	_preview = preview
	_update_preview_doll()

	return true
