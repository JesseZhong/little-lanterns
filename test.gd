extends Node2D

var player_spawner = PlayerSpawner.new()
var monster_spawner = MonsterSpawner.new()


func _ready() -> void:
	player_spawner.spawn(
		self,
		Vector2(20, 10),
		'novice',
		CharacterStats.new(300, 120, 1.4, 25),
		{'follow_camera': {'enabled': true, 'zoom': Vector2(4, 4)}}
	)

	monster_spawner.spawn(
		self, Vector2(320, 120), 'orc', CharacterStats.new(400, 67, 1.2, 43), {'faction': 'orcs'}
	)

	monster_spawner.spawn(
		self,
		Vector2(310, 70),
		'orc',
		CharacterStats.new(
			450,
			72,
			1.1,
			48
		),
		{
			'faction': 'orcs'
		}
	)

	monster_spawner.spawn(
		self,
		Vector2(334, 54),
		'orc',
		CharacterStats.new(
			430,
			65,
			1.21,
			41
		),
		{
			'faction': 'orcs'
		}
	)
