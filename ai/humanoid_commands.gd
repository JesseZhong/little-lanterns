class_name HumanoidCommands

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


# Checks if the target is in range and strikes if they are.
func _careful_strike(target: AiTarget, tolerable_distance: float) -> Callable:
  return func (ai_controller: AiController):
    if (target.position - ai_controller.position).length() <= tolerable_distance:
      pass

func _stalk(target: AiTarget):
  var target_position = target.position
  var target_face_direction = target.controller.character.move_direction
  
  pass

func _circle(target: AiTarget):
  pass