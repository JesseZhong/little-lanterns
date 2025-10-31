extends Area2D
signal hit

@export var speed = 400 # How fast the player will move (pixels/sec).
var screen_size # Size of the game window.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  screen_size = get_viewport_rect().size
  $CharacterAnimation.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
  var velocity = Vector2.ZERO # The player's movement vector.
  if Input.is_action_pressed("move_right"):
    velocity.x += 1
  if Input.is_action_pressed("move_left"):
    velocity.x -= 1
  if Input.is_action_pressed("move_down"):
    velocity.y += 1
  if Input.is_action_pressed("move_up"):
    velocity.y -= 1

  if velocity.length() > 0:
    velocity = velocity.normalized() * speed
    if velocity.x > 0:
      $CharacterAnimation.animation = 'walk_right'
    elif velocity.x < 0:
      $CharacterAnimation.animation = 'walk_left'
    elif velocity.y != 0:
      $CharacterAnimation.animation = 'walk_down' if velocity.y > 0 else 'walk_up'
  else:
    $CharacterAnimation.animation = 'idle'
    
  position += velocity * delta
  position = position.clamp(Vector2.ZERO, screen_size)


func _on_body_entered(body: Node2D) -> void:
  hide() # Player disappears after being hit.
  hit.emit()
  # Must be deferred as we can't change physics properties on a physics callback.
  $CollisionShape2D.set_deferred("disabled", true)
  
func start(pos):
  position = pos
  show()
  $CollisionShape2D.disabled = false
