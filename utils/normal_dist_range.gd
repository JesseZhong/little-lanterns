## Random number generator whose probability
## follows normal distribution and is clamped
## to a number range.
class_name NormalDistRange
extends Object

var value: float:
  get:
    return clamp(_rng.randfn(_mean, _deviation), _low, _high)

var _rng: RandomNumberGenerator

var _mean: float
var _deviation: float
var _low: float
var _high: float

static func generate(
  mean: float,
  deviation: float,
  low: float,
  high: float,
) -> float:
  var instance = NormalDistRange.new(
    mean,
    deviation,
    low,
    high,
  )
  return instance.value;

func _init(
  mean: float,
  deviation: float,
  low: float,
  high: float,
) -> void:
  _low = low
  _high = high
  _mean = mean
  _deviation = deviation
  _rng = RandomNumberGenerator.new()
  _rng.randomize()
  
