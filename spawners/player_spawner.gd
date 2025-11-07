class_name PlayerSpawner
extends Spawner

# https://docs.godotengine.org/en/stable/classes/class_%40gdscript.html#class-gdscript-method-preload
# https://docs.godotengine.org/en/stable/tutorials/best_practices/logic_preferences.html#loading-vs-preloading
const player_scene: PackedScene = preload('res://controllers/player.tscn')

func spawn(
  world: Node,
  spawn_location: Vector2,
  character_name: String,
  character_stats: CharacterStats,
  options: Dictionary[String, Variant] = {}
):
  # Ensure character stats are valid.
  if not character_stats:
    print_debug('Valid character stats required for spawning.')
    return
  
  # Attempt to locating the requested scene.
  var character_scene = _get_character_scene(character_name)
  
  if character_scene \
    and character_scene.can_instantiate() \
    and player_scene \
    and player_scene.can_instantiate():
      
    var condition = CharacterCondition.new(character_stats)
      
    var character: Character2D = character_scene.instantiate()
    character.setup(spawn_location, condition)

    # Initialize a new player controller
    # and attach the character scene.
    var player: Player = player_scene.instantiate()
    player.setup(character)
    
    # Attach stats, condition, and character.
    player.add_child(character_stats)
    player.add_child(condition)
    player.add_child(character)
  
    # Setup a camera that can follow a character.
    var camera_options = options.get('follow_camera')
    if camera_options:
      var camera = FollowCamera2D.new(
        character,
        camera_options.get('enabled'),
        camera_options.get('zoom')
      )
      player.add_child(camera)
    
    # Finally, add to scene.
    world.add_child(player)

func _get_character_scene(character_name: String) -> PackedScene:
  # https://docs.godotengine.org/en/stable/classes/class_%40gdscript.html#class-gdscript-method-load
  match(character_name):
    'novice', _:
      return load('res://characters/novice.tscn')
