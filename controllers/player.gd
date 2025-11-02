extends Controller

func _ready() -> void:
  super._ready()

func _process(_delta: float) -> void:
  if character:
      var move = Vector2.ZERO
      if Input.is_action_pressed("move_right"):
        move.x += 1
      if Input.is_action_pressed("move_left"):
        move.x -= 1
      if Input.is_action_pressed("move_down"):
        move.y += 1
      if Input.is_action_pressed("move_up"):
        move.y -= 1

      if Input.is_action_pressed('light_attack'):
        character.action = 'light_attack'
      elif move.length() > 0:
        character.move_direction = move
        character.action = 'move'
      else:
        character.move_direction = Vector2.ZERO
        character.action = 'idle'
