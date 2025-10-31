extends Node

var TILE_WIDTH = 32
var TILE_LENGTH = 28
var TILE_HEIGHT = 6
var BASE_Z = -4

@export var terrain_tile: PackedScene
@export var layout: Array[Dictionary]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate_map()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func generate_map():
	for tile_data in layout:
		var position: Vector2 = tile_data.position
		var level: int = tile_data.level
		var tile_type: String = tile_data.tile_type
		
		var tile = terrain_tile.instantiate()
		tile.terrain_type = tile_type
		
		# Layer the tiles based off elevation.
		var z = BASE_Z + level
		tile.z_index = z
		
		# Position the tiles accounting for size and elevation.
		tile.position = Vector2(
			position.x * TILE_WIDTH,
			position.y * TILE_LENGTH + z * BASE_Z)
		
		add_child(tile)
