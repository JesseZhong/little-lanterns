class_name MonsterSpawner
extends Spawner

func spawn(
  world: Node,
  spawn_location: Vector2,
  character_name: String,
  character_stats: CharacterStats,
  _options: Dictionary[String, Variant] = {}
):
  # Ensure character stats are valid.
  if not character_stats:
    print_debug('Valid character stats required for spawning.')
    return
  
  # Attempt to get AI and character scenes.
  var scenes = _get_character_scene(character_name)
  var ai_scene: PackedScene = scenes[0]
  var character_scene: PackedScene = scenes[1]
  
  if character_scene \
    and character_scene.can_instantiate() \
    and ai_scene \
    and ai_scene.can_instantiate():

    # Initialize a new AI controller
    # and attach the character scene.
    var ai: Controller = ai_scene.instantiate()
    ai.start_position = spawn_location
    ai.character_scene = character_scene
    
    # Attach stats and condition.
    ai.add_child(character_stats)
    var condition = CharacterCondition.new(character_stats)
    ai.setup(condition)
    ai.add_child(condition)
    
    # Finally, add to scene.
    world.add_child(ai)

func _get_character_scene(character_name: String) -> Array:
  # https://docs.godotengine.org/en/stable/classes/class_%40gdscript.html#class-gdscript-method-load
  match(character_name):
    'orc', _:
      return [
        load('res://controllers/orc_ai.tscn'),
        load('res://characters/orc.tscn')
      ]
