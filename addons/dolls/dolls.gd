@tool
extends EditorPlugin

const RAGDOLL_SCENE := preload("res://Ragdoll.tscn")

var _button: Button = null
var _catcher: Control = null
var _preview: Control = null
var _ragdoll: Node2D = null

var _canvas_editor: Control = null # CanvasItemEditor


func _enter_tree() -> void:
	_button = Button.new()
	_button.text = "FREE RAGDOLLS!"
	_button.icon = get_editor_interface().get_editor_theme().get_icon("ViewportSpeed", "EditorIcons")
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, _button)
	_button.get_parent().move_child(_button, _button.get_index() - 2)

	PhysicsServer2D.set_active(true)
	_button.set_drag_forwarding(_get_doll_drag_data, Callable(), Callable())

	var dummy := Control.new()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, dummy)
	_canvas_editor = dummy.get_parent().get_parent().get_parent().get_parent().get_parent()
	var canvas_viewport: Control = _canvas_editor.get_child(1).get_child(0).get_child(0).get_child(0).get_child(1)
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, dummy)

	_catcher = Control.new()
	_catcher.mouse_filter = Control.MOUSE_FILTER_PASS
	canvas_viewport.add_child(_catcher)
	_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	#_catcher.draw.connect(_debug_draw_catcher)
	_catcher.queue_redraw()

	_catcher.set_drag_forwarding(Callable(), _can_doll_drag_drop, _doll_drag_drop)


func _exit_tree() -> void:
	if is_instance_valid(_button):
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, _button)
		_button.queue_free()
		_button = null

	if is_instance_valid(_catcher):
		_catcher.get_parent().remove_child(_catcher)
		_catcher.queue_free()
		_catcher = null

	PhysicsServer2D.set_active(false)


func _debug_draw_catcher() -> void:
	_catcher.draw_rect(Rect2(Vector2.ZERO, _catcher.size), Color(1.0, 0.0, 0.0, 0.23))


func _process(_delta: float) -> void:
	_update_preview_doll()


func _get_doll_drag_data(_at_position: Vector2) -> Variant:
	var preview := Control.new()
	_ragdoll = RAGDOLL_SCENE.instantiate()
	_ragdoll.top_level = true
	_ragdoll.global_position = get_viewport().get_mouse_position() + Vector2(0, 120)
	preview.add_child(_ragdoll)

	_preview = preview
	_setup_preview_doll()

	_button.set_drag_preview(preview)
	_update_preview_doll()

	return DollDragData.new()


func _can_doll_drag_drop(_at_position: Vector2, data: Variant) -> bool:
	if data is DollDragData:
		return true

	return false


func _doll_drag_drop(at_position: Vector2, data: Variant) -> void:
	if data is not DollDragData:
		return

	var target_node: Node = get_editor_interface().get_edited_scene_root()
	var canvas_position := target_node.get_viewport().global_canvas_transform.affine_inverse() * at_position

	_ragdoll.get_parent().remove_child(_ragdoll)
	var skeleton: Skeleton2D = _ragdoll.get_node("Skeleton")
	target_node.add_child(_ragdoll)
	_freeze_physical_bones(skeleton.get_node("PBody"))

	var phead: PhysicalBone2D = skeleton.get_node("PBody/PNeck/PHead")
	_ragdoll.global_position -= (phead.global_position - canvas_position)


func _setup_preview_doll() -> void:
	if not is_instance_valid(_preview) || not is_instance_valid(_ragdoll):
		return

	var skeleton: Skeleton2D = _ragdoll.get_node("Skeleton")
	_cleanup_skeleton_bones(skeleton.get_node("Body"))
	_cleanup_physical_bones(skeleton.get_node("PBody"))


func _cleanup_skeleton_bones(from_bone: Bone2D) -> void:
	from_bone.set("editor_settings/show_bone_gizmo", false)

	for child_node in from_bone.get_children():
		if child_node is Bone2D:
			_cleanup_skeleton_bones(child_node)


func _cleanup_physical_bones(from_bone: PhysicalBone2D) -> void:
	var bone_shape: Node2D = from_bone.get_node_or_null("Shape")
	if bone_shape:
		bone_shape.visible = false

	var bone_joint: Node2D = from_bone.get_node_or_null("PinJoint2D")
	if bone_joint:
		bone_joint.visible = false

	for child_node in from_bone.get_children():
		if child_node is PhysicalBone2D:
			_cleanup_physical_bones(child_node)


func _freeze_physical_bones(from_bone: PhysicalBone2D) -> void:
	from_bone.freeze = true

	for child_node in from_bone.get_children():
		if child_node is PhysicalBone2D:
			_freeze_physical_bones(child_node)


func _update_preview_doll() -> void:
	if not is_instance_valid(_preview) || not is_instance_valid(_ragdoll):
		return

	var skeleton: Skeleton2D = _ragdoll.get_node("Skeleton")
	var phead: PhysicalBone2D = skeleton.get_node("PBody/PNeck/PHead")

	phead.global_position = _preview.global_position


class DollDragData:
	pass
