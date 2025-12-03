class_name MonsterSpawner
extends Spawner


func spawn(
	world: Node,
	spawn_location: Vector2,
	character_name: String,
	character_stats: CharacterStats,
	options: Dictionary[String, Variant] = {}
):
	# Ensure character stats are valid.
	assert(character_stats, 'Valid character stats required for spawning.')

	# Attempt to get AI and character scenes.
	var scenes = _get_character_scene(character_name)
	var controller_scene: PackedScene = scenes[0]
	var character_scene: PackedScene = scenes[1]

	if (
		character_scene
		and character_scene.can_instantiate()
		and controller_scene
		and controller_scene.can_instantiate()
	):
		var condition = CharacterCondition.new(character_stats)

		var agent = NavigationAgent2D.new()
		agent.path_desired_distance = 2.0
		agent.target_desired_distance = 2.0

		var character: Character2D = character_scene.instantiate()
		character.setup(spawn_location, condition)
		character.add_child(agent)

		# Initialize a new AI controller, set faction,
		# and attach the character and agent.
		var controller: Controller = controller_scene.instantiate()
		controller.faction = options.get('faction', '')
		controller.setup(character, condition, agent)

		# Attach stats, condition, and character.
		controller.add_child(character_stats)
		controller.add_child(condition)
		controller.add_child(character)

		# Destroy and clear monster when it dies.
		condition.death.connect(func(): controller.queue_free())

		# Finally, add to scene.
		world.add_child(controller)


func _get_character_scene(character_name: String) -> Array:
	# https://docs.godotengine.org/en/stable/classes/class_%40gdscript.html#class-gdscript-method-load
	match character_name:
		'orc', _:
			return [
				load('res://controllers/orc_controller.tscn'), load('res://characters/orc.tscn')
			]
