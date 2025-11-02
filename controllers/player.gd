extends Controller

var speed: int = 120

func _ready() -> void:
  super._ready()

func _process(_delta: float) -> void:
  if character:
      var velocity = Vector2.ZERO
      if Input.is_action_pressed("move_right"):
        velocity.x += 1
      if Input.is_action_pressed("move_left"):
        velocity.x -= 1
      if Input.is_action_pressed("move_down"):
        velocity.y += 1
      if Input.is_action_pressed("move_up"):
        velocity.y -= 1

      if velocity.length() > 0:
        var normalized_velocity = velocity.normalized()
        if Input.is_action_pressed('light_attack'):
          character.move_velocity = normalized_velocity
          character.action = 'light_attack'
        else:
          character.move_velocity = normalized_velocity * speed
          character.action = 'move'
      else:
        character.move_velocity = Vector2.ZERO
        character.action = 'idle'
