@tool
extends Node2D

const FREEZE_TIMEOUT := 4.0

var _freeze_after_birth: bool = false
var _freeze_timer: float = 0.0

@onready var _skeleton = %Skeleton


func _ready()->void:
	var modification_stack: SkeletonModificationStack2D = _skeleton.get_modification_stack()
	var modification_physical_bones: SkeletonModification2DPhysicalBones = modification_stack.get_modification(0)
	modification_physical_bones.fetch_physical_bones()

	for i in modification_physical_bones.physical_bone_chain_length:
		var p_bone_path := modification_physical_bones.get_physical_bone_node(i)
		var p_bone: PhysicalBone2D = _skeleton.get_node(p_bone_path)

		if p_bone.freeze:
			PhysicsServer2D.body_set_mode(p_bone.get_rid(), PhysicsServer2D.BODY_MODE_STATIC)
		else:
			PhysicsServer2D.body_set_mode(p_bone.get_rid(), PhysicsServer2D.BODY_MODE_RIGID)

	modification_physical_bones.start_simulation()


func _enter_tree() -> void:
	_freeze_timer = FREEZE_TIMEOUT


func _process(delta: float) -> void:
	if not _freeze_after_birth || _freeze_timer <= 0:
		return

	_freeze_timer -= delta
	if _freeze_timer <= 0:
		var modification_stack: SkeletonModificationStack2D = _skeleton.get_modification_stack()
		var modification_physical_bones: SkeletonModification2DPhysicalBones = modification_stack.get_modification(0)
		modification_physical_bones.fetch_physical_bones()

		for i in modification_physical_bones.physical_bone_chain_length:
			var p_bone_path := modification_physical_bones.get_physical_bone_node(i)
			var p_bone: PhysicalBone2D = _skeleton.get_node(p_bone_path)
			p_bone.freeze = true
