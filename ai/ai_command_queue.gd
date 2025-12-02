## Manages AI commands to be executed.
class_name AiCommandQueue
extends RefCounted

signal command_executed()
signal command_finished()


var executing: bool:
  get: return _executing

var has_commands: bool:
  get: return len(_queue) > 0

var _queue: Array = []
var _ai_controller: AiController
var _executing: bool = false
var _end_condition: AiConstants.EndConditions


func _init(
  ai_controller: AiController
) -> void:
  _ai_controller = ai_controller


## Attempts to dequeue and execute the next command,
## as long as no previous one still executing.
## Returns whether a new command was executed or not.
func execute() -> bool:
  if has_commands and !_executing:
    var ai_action: Callable = _queue.pop_front()
    if ai_action:
      _end_condition = ai_action.call(_ai_controller)

      # Emit that a command has started execution.
      command_executed.emit()

      return true

  return false


## Clears the command queue.
func clear_queue() -> void:
  _queue.clear()


## Attempt to queue and execute command(s).
func do(command_s: Variant, now = false) -> void:
  assert(command_s, 'Cannot queue null command(s).')
  assert(
    command_s is Callable or
    command_s is Array[Callable] or
    # For untyped/ambiguous arrays.
    (command_s is Array and command_s.all(func(x): return x is Callable)),
    'Argument must be a command or list of commands.'
  )

  if command_s is Callable:
    var single = command_s as Callable

    # Demanded now or have nothing queued up?
    # Clear queue and execute now.
    if now or !has_commands:
      clear_queue()
      _end_condition = single.call(_ai_controller)

      # Block other commands from being executed until this one finishes.
      _executing = true

      # Emit that a command has started execution.
      command_executed.emit()

    # Already a queue? Wait.
    else:
      _queue.append(single)
  else:
    var list = command_s as Array[Callable]

    # If not demanded now, no previous commands are queued,
    # or there isn't a command currently executing, attempt
    # to execute the first command now.
    if now or !has_commands and !_executing:
      clear_queue()

      # Grab first command to execute now.
      var first_command = list.pop_front()

      # Queue the rest.
      _queue.append_array(list)

      # Execute the command.
      _end_condition = first_command.call(_ai_controller)

      # Block other commands from executing until this one finishes.
      _executing = true

      # Emit that a command has started execution.
      command_executed.emit()

    # Throw them into the queue.
    else:
      _queue.append_array(list)


## Attempts to stop any executing command by passing an end condition.
## If the condition matches the one required by an executing command,
## the command is resolved and a signal is emitted.
func try_finish(end_condition: AiConstants.EndConditions) -> bool:
  if _executing and (end_condition == _end_condition or AiConstants.EndConditions.INTERRUPTED == end_condition):
    _executing = false
    command_finished.emit()
    return true

  return false
