class_name Query
extends Node

static func foreach(dict: Dictionary, predicate: Callable) -> void:
  assert(dict is Dictionary, 'Query error: Invalid dictionary.')
  assert(predicate, 'Query error: Invalid predicate.')
  
  for key in dict:
    predicate.call(key, dict[key])

## Attempts to find the first value that satisfies the predicate.
## Otherwise, return null.
static func first(dict: Dictionary, predicate: Callable) -> Variant:
  assert(dict is Dictionary, 'Query error: Invalid dictionary.')
  assert(predicate, 'Query error: Invalid predicate.')
    
  for key in dict:
    var value = dict.get(key)
    var result = predicate.call(value)
    
    if result:
      return value
      
  return null

## Determines the entry with the highest valued property and returns the key.
## `predicate` chooses which property in the value to compare.
static func max(dict: Dictionary, predicate: Callable) -> Variant:
  assert(dict is Dictionary, 'Query error: Invalid dictionary.')
  assert(predicate, 'Query error: Invalid predicate.')
    
  var length = len(dict)
  if length < 1:
    return null
    
  var keys = dict.keys()
  var max_key = keys[0]
  var max_val = predicate.call(dict[max_key])
    
  for i in range(1, length - 1):
    var key = keys[i]
    var val = predicate.call(dict[key])
    
    if val > max_val:
      max_key = key
      max_val = val
    
  return max_key
