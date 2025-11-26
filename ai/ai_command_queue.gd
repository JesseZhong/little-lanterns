## Manages AI commands to be executed.
class_name AiCommandQueue
extends RefCounted

var has_commands: bool:
  get: return len(_queue) > 0

var _queue: Array = []
var _ai_controller: AiController


func _init(
  ai_controller: AiController
) -> void:
  _ai_controller = ai_controller


## Attempts to dequeue and execute the next command,
## as long as no previous 
func execute():
  if has_commands:
    var ai_action: Callable = _queue.pop_front()
    if ai_action:
      ai_action.call(_ai_controller)


## Clears the command queue.
func clear_queue() -> void:
  _queue.clear()


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
      single.call(_ai_controller)

    # Already a queue? Wait.
    else:
      _queue.append(single)
  else:
    var list = command_s as Array[Callable]

    if now or !has_commands:
      clear_queue()

      # Grab first command to execute now.
      var first_command = list.pop_front()

      # Queue the rest.
      _queue.append_array(list)

      # Execute the command.
      first_command.call(_ai_controller)

    # Throw them into the queue.
    else:
      _queue.append_array(list)
