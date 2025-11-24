class_name HumanoidCommands

const STEP_DISTANCE = 5.3


## Have character walk to a random location near the patrol point.
static func wander_patrol(
  target_position: Vector2,
  walk_distance: float,
  fan_angle: float,
  pause_time: float,
) -> Array[Callable]:
  return [
    func (ai_controller: AiController):
      ai_controller.wait(pause_time),

    # Walk randomly around target position.
    func (ai_controller: AiController):
      var angle_to_patrol_point = (target_position - ai_controller.character.position).angle()
      var half_fan_angle = fan_angle / 2
      var direction = randf_range(
        -half_fan_angle, half_fan_angle
      ) + angle_to_patrol_point
      ai_controller.move_to(
        VectorMath.extend(
          ai_controller.character.position,
          walk_distance,
          direction,
        ),
        'walk',
      )
  ]


## Close in on the target, from an angle that can be attacked from.
static func rush(
  target: AiTarget,
  offset: Vector2,
) -> Callable:
  return func (ai_controller: AiController):
    var angle_of_approach = target.position - ai_controller.character.position

    #_run_to(ai_target.position + Vector2(10, 10))


# Checks if the target is in range and only strikes if they are.
# Requires directional sense on the character.
static func careful_strike(target: AiTarget) -> Callable:
  return func (ai_controller: AiController):
    var sense = ai_controller.character.attack_sense
    if sense:
      var direction = sense.where_target(target.controller)
      if direction:
        ai_controller.character.turn(direction)
        ai_controller.character.act('light_attack')
        return
    
    ai_controller.go_next()


func _stalk(target: AiTarget):
  var target_position = target.position
  #var target_face_direction = target.controller.character.act('walk', Vector2.ZERO)
  
  pass


static func circle(
  ai_controller: AiController,
  target: AiTarget,
  distance: float,
  clockwise: bool,
  move_type: String,
) -> Array[Callable]:
  assert(distance > 0, '')

  # Account for remainder.
  var steps = floor(distance / STEP_DISTANCE) + 1
  var path: Array[Vector2] = []
  var result: Array[Callable] = []

  # Quick maths.
  var center = target.position
  var radius = (ai_controller.character.position - target.position).length()
  var travel_angle = distance / radius * (-1 if clockwise else 1)
  var step_angle = travel_angle / steps

  # Calculate the path the character will take.
  for i in range(steps):
    var angle = step_angle * i
    var x = center.x + radius * cos(angle)
    var y = center.y + radius * sin(angle)
    path.append(Vector2(x, y))

  # Populate movement commands.
  assert(steps == len(path))
  for destination in path:
    result.append(
      func (ac: AiController):
        ac.move_to(destination, move_type)
    )

  return result
