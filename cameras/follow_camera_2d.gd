## Camera that follows a target around the world.
class_name FollowCamera2D
extends Camera2D

# Used to track the target's position
# and update the camera's position.
var _target_transform: RemoteTransform2D

func _init(
  target: Node2D,
  enable_camera: bool,
  start_zoom: Vector2
) -> void:
  if target is not Node2D:
    print_debug('Error: Invalid camera target.')
    return
  
  # Setup the transform and attach it to the target.
  _target_transform = RemoteTransform2D.new()
  _target_transform.update_rotation = false
  target.add_child(_target_transform)
  
  enabled = enable_camera
  zoom = start_zoom
  
  add_to_group('follow_cameras')
  
# Once the camera is available in the scene tree,
# pass its path to the remote transform.
func _ready() -> void:
  _target_transform.remote_path = get_path()
