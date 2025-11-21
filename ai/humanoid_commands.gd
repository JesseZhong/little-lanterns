class_name HumanoidCommands

const STEP_DISTANCE = 5.3

static func walk_to(
  target_position: Vector2
) -> Callable:
  return func (ai_controller):
    ai_controller.nav_agent.target_position = target_position
    ai_controller.character.act('walk')

static func run_to(
  target_position: Vector2
) -> Callable:
  return func (ai_controller):
    ai_controller.nav_agent.target_position = target_position
    ai_controller.character.act('run')

## Have character walk to a random location near the patrol point.
static func patrol_wander(
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
      var angle_to_patrol_point = ai_controller.position.angle_to(target_position)
      var half_fan_angle = fan_angle / 2
      var direction = randf_range(
        -half_fan_angle, half_fan_angle
      ) + angle_to_patrol_point
      walk_to(VectorMath.extend(
        ai_controller.position,
        walk_distance,
        direction
      )).call(ai_controller)
  ]

## Close in on the target, from an angle that can be attacked from.
static func rush(
  target: AiTarget,
  offset: Vector2,
) -> Callable:
  return func (ai_controller: AiController):
    var angle_of_approach = target.position - ai_controller.position

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
  var target_face_direction = target.controller.character.move_direction
  
  pass

static func circle(
  ai_controller: AiController,
  target: AiTarget,
  distance: float,
  clockwise: bool,
  run: bool
) -> Array[Callable]:
  assert(distance > 0, '')

  # Account for remainder.
  var steps = floor(distance / STEP_DISTANCE) + 1
  var path: Array[Vector2] = []
  var result: Array[Callable] = []

  # Quick maths.
  var center = target.position
  var radius = (ai_controller.position - target.position).length()
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
    var method = run_to if run else walk_to
    result.append(method.call(destination))

  return result
