@tool
extends StaticBody2D

@export_group("Terrain Properties")

@export_enum('earth', 'dirt', 'grass')
var terrain_type: String = '':
  set(value):
    terrain_type = value
    update_terrain()

@export
var terrain_variant: String = '':
  set(value):
    terrain_variant = value
    update_terrain()

@export_range(0, 20)
var elevation_level: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  $AnimatedSprite2D.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
  update_terrain()
  

func update_terrain():
  var terrain_name = get_terrain_name(terrain_type, terrain_variant)
  $AnimatedSprite2D.animation = terrain_name

  
func get_terrain_name(terrainType: String, terrainVariant: String) -> String:
  var normalize = func () -> String:
    match terrainType:
      'earth', 'dirt':
        return 'earth'
      'grass', _:
        return 'default'
        
  return '{type}#{variant}'.format({
      'type': normalize.call(),
      'variant': terrainVariant
    }) \
    if terrainVariant \
    else normalize.call()
