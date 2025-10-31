@abstract class_name Character2D
extends Area2D

signal on_hit

var velocity: Vector2 = Vector2.ZERO
var action: String = 'idle'
var anim_player: AnimationPlayer
var block_anim: bool = false

func stand(_delta: float):
  smooth_play('idle')

func move(delta: float):
  if velocity.length() > 0:
    var x = velocity.x
    var y = velocity.y
    if abs(y) > abs(x):
      if y > 0:
        smooth_play('walk_down')
      elif y < 0:
        smooth_play('walk_up')
    else:
      if x > 0:
        smooth_play('walk_right')
      elif x < 0:
        smooth_play('walk_left')
        
    position += velocity * delta

func get_hit(_delta: float):
  var direction = calc_face_direction(velocity)
  smooth_play('hit_%s' % direction)
  
func light_attack(_delta: float):
  var direction = calc_face_direction(velocity)
  smooth_play('light_attack_%s' % direction)

func smooth_play(animation_name: String):
  if animation_name != anim_player.assigned_animation:
    anim_player.play("RESET")
    anim_player.advance(0)
  anim_player.play(animation_name)

func calc_face_direction(vector: Vector2) -> String:
  match(vector):
    var v when v.normalized().dot(Vector2.DOWN) > 0: 
      return 'down'
    var v when v.normalized().dot(Vector2.UP) > 0:
      return 'up'
    var v when v.normalized().dot(Vector2.LEFT) > 0:
      return 'left'
    var v when v.normalized().dot(Vector2.RIGHT) > 0:
      return 'right'
    _:
      return 'down'
      
func process_additional_actions(_action: String, _delta: float) -> bool:
  return false
  
func block_animations():
  block_anim = true

func unblock_animations():
  block_anim = false

func _ready() -> void:
  anim_player = $AnimationPlayer

func _process(delta: float) -> void:
  if anim_player:
    if block_anim:
      if action == 'get_hit':
        get_hit(delta)
    else:
      match(action):
        'stand':
          stand(delta)
        'move':
          move(delta)
        'light_attack':
          light_attack(delta)
        var a:
          if not process_additional_actions(a, delta):
            stand(delta)
