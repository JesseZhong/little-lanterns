## Camera that follows a controller around the world.
class_name FollowCamera2D
extends Camera2D

var _target: Controller

func _init(
  camera_target: Controller,
  enable_camera: bool,
  start_zoom: Vector2
) -> void:
  if camera_target is not Controller:
    print_debug('Error: Invalid follow camera _target.')
    return
  _target = camera_target
  enabled = enable_camera
  zoom = start_zoom
  add_to_group('follow_cameras')

# Update the camera's position to the parent's.
func _process(_delta: float) -> void:
  if _target:
    position = _target.current_position
