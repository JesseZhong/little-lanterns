extends GutTest

var character: Character2D

func before_each():
  character = partial_double(Character2D).new()
