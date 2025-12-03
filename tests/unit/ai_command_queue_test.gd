extends GutTest
# Note:
# AiCommandQueue relies on side effects to work.
# To isolate testing properties and methods,
# these tests manipulated the internal queue directly.
# Normally, this is not advised.

var _queue: AiCommandQueue
var _ai_controller: AiController


func before_all():
	# Register stub with GUT.
	register_inner_classes(get_script())


func before_each():
	# Character stub setup.
	var stats = partial_double(CharacterStats).new(1, 1, 1, 1)
	var condition = double(CharacterCondition).new(stats)
	var character = double(Character2D).new()

	# Controller setup and queue interdependency.
	_ai_controller = StubAiController.new()
	_ai_controller.setup(character, condition)
	_ai_controller.add_child(character)
	_queue = AiCommandQueue.new(_ai_controller)

	# Manually assign queue; usually done in `setup()`.
	_ai_controller._queue = _queue

	# Add to autofree tree and trigger `_ready()`.
	add_child_autofree(_ai_controller)


func test_do__empty_list__add_single():
	var callback = partial_double(Callback).new()

	_queue.do(callback.method)

	# Execute the callback and queue nothing.
	assert_called(callback.method.bind(_ai_controller))
	assert_true(_queue._queue.is_empty())


func test_do__existing_list__add_single():
	var callback_1 = partial_double(Callback).new()
	var callback_2 = partial_double(Callback).new()
	var callback_3 = partial_double(Callback).new()
	_queue._queue = [
		callback_1.method,
		callback_2.method,
	]

	_queue.do(callback_3.method)

	# Should not execute anything and queue the command.
	assert_not_called(callback_1.method)
	assert_not_called(callback_2.method)
	assert_not_called(callback_3.method)
	assert_eq_deep(
		_queue._queue,
		[
			callback_1.method,
			callback_2.method,
			callback_3.method,
		]
	)


func test_do_now__empty_list__add_single():
	var callback = partial_double(Callback).new()

	_queue.do(callback.method, true)

	# Execute the callback. Nothing should be in the queue.
	assert_called(callback.method.bind(_ai_controller))
	assert_true(_queue._queue.is_empty())


func test_do_now__existing_list__add_single():
	var callback_1 = partial_double(Callback).new()
	var callback_2 = partial_double(Callback).new()
	var callback_3 = partial_double(Callback).new()
	_queue._queue = [
		callback_1.method,
		callback_2.method,
	]

	_queue.do(callback_3.method, true)

	# Clear existing queue and execute passed callback.
	assert_not_called(callback_1.method)
	assert_not_called(callback_2.method)
	assert_called(callback_3.method.bind(_ai_controller))
	assert_true(_queue._queue.is_empty())


func test_do__empty_list__add_list_single():
	var callback = partial_double(Callback).new()
	var commands = [callback.method]

	_queue.do(commands)

	# Execute the single and add nothing to the queue.
	assert_called(callback.method.bind(_ai_controller))
	assert_true(_queue._queue.is_empty())


func test_do__empty_list__add_list_many():
	var callback_1 = partial_double(Callback).new()
	var callback_2 = partial_double(Callback).new()
	var callback_3 = partial_double(Callback).new()
	var commands = [
		callback_1.method,
		callback_2.method,
		callback_3.method,
	]

	_queue.do(commands)

	# Execute the first and add the rest to the queue.
	assert_called(callback_1.method.bind(_ai_controller))
	assert_not_called(callback_2.method)
	assert_not_called(callback_3.method)
	assert_eq_deep(
		_queue._queue,
		[
			callback_2.method,
			callback_3.method,
		]
	)


func test_do__existing_list__add_list_single():
	var callback_1 = partial_double(Callback).new()
	var callback_2 = partial_double(Callback).new()
	var callback_3 = partial_double(Callback).new()
	_queue._queue = [
		callback_1.method,
		callback_2.method,
	]
	var commands = [callback_3.method]

	_queue.do(commands)

	# Should add to the queue but not execute anything.
	assert_not_called(callback_1.method)
	assert_not_called(callback_2.method)
	assert_not_called(callback_3.method)
	assert_eq_deep(
		_queue._queue,
		[
			callback_1.method,
			callback_2.method,
			callback_3.method,
		]
	)


func test_do__existing_list__add_list_many():
	var callback_1 = partial_double(Callback).new()
	var callback_2 = partial_double(Callback).new()
	var callback_3 = partial_double(Callback).new()
	var callback_4 = partial_double(Callback).new()
	var callback_5 = partial_double(Callback).new()
	_queue._queue = [
		callback_1.method,
		callback_2.method,
		callback_3.method,
	]
	var commands = [
		callback_4.method,
		callback_5.method,
	]

	_queue.do(commands)

	# Should add to the queue but not execute anything.
	assert_not_called(callback_1.method)
	assert_not_called(callback_2.method)
	assert_not_called(callback_3.method)
	assert_not_called(callback_4.method)
	assert_not_called(callback_5.method)
	assert_eq_deep(
		_queue._queue,
		[
			callback_1.method,
			callback_2.method,
			callback_3.method,
			callback_4.method,
			callback_5.method,
		]
	)


func test_do_now__empty_list__add_list_single():
	var callback = partial_double(Callback).new()
	var commands = [callback.method]

	_queue.do(commands, true)

	# Execute the single. Nothing should be in the queue.
	assert_called(callback.method.bind(_ai_controller))
	assert_true(_queue._queue.is_empty())


func test_do_now__empty_list__add_list_many():
	var callback_1 = partial_double(Callback).new()
	var callback_2 = partial_double(Callback).new()
	var callback_3 = partial_double(Callback).new()
	var commands = [
		callback_1.method,
		callback_2.method,
		callback_3.method,
	]

	_queue.do(commands, true)

	# Execute the first and add the rest to the queue.
	assert_called(callback_1.method.bind(_ai_controller))
	assert_not_called(callback_2.method)
	assert_not_called(callback_3.method)
	assert_eq_deep(
		_queue._queue,
		[
			callback_2.method,
			callback_3.method,
		]
	)


func test_do_now__existing_list__add_list_single():
	var callback_1 = partial_double(Callback).new()
	var callback_2 = partial_double(Callback).new()
	var callback_3 = partial_double(Callback).new()
	_queue._queue = [
		callback_1.method,
		callback_2.method,
	]
	var commands = [callback_3.method]

	_queue.do(commands, true)

	# Clear queue and execute single.
	assert_not_called(callback_1.method)
	assert_not_called(callback_2.method)
	assert_called(callback_3.method.bind(_ai_controller))
	assert_true(_queue._queue.is_empty())


func test_do_now__existing_list__add_list_many():
	var callback_1 = partial_double(Callback).new()
	var callback_2 = partial_double(Callback).new()
	var callback_3 = partial_double(Callback).new()
	var callback_4 = partial_double(Callback).new()
	var callback_5 = partial_double(Callback).new()
	_queue._queue = [
		callback_1.method,
		callback_2.method,
		callback_3.method,
	]
	var commands = [
		callback_4.method,
		callback_5.method,
	]

	_queue.do(commands, true)

	# Clear queue, execute first, and queue the rest.
	assert_not_called(callback_1.method)
	assert_not_called(callback_2.method)
	assert_not_called(callback_3.method)
	assert_called(callback_4.method.bind(_ai_controller))
	assert_not_called(callback_5.method)
	assert_eq_deep(
		_queue._queue,
		[
			callback_5.method,
		]
	)


func test_execute__list_single():
	var callback = partial_double(Callback).new()
	_queue._queue = [callback.method]

	_queue.execute()

	# Should execute the single and leave an empty queue.
	assert_called(callback.method.bind(_ai_controller))
	assert_true(_queue._queue.is_empty())


func test_execute__list_many():
	var callback = partial_double(Callback).new()
	_queue._queue = [
		callback.method,
		func(_ai): pass,
		func(_ai): pass,
	]

	_queue.execute()

	# Should execute the first and leave the rest.
	assert_called(callback.method.bind(_ai_controller))
	assert_eq(len(_queue._queue), 2)


func test_clear_queue():
	_queue._queue = [
		func(_ai): pass,
		func(_ai): pass,
		func(_ai): pass,
	]

	_queue.clear_queue()

	assert_true(_queue._queue.is_empty())


var has_commands_params = ParameterFactory.named_parameters(
	['commands', 'expected_result'],
	[
		[[], false],
		[
			[
				func(_ai): pass,
			],
			true,
		],
		[
			[
				func(_ai): pass,
				func(_ai): pass,
				func(_ai): pass,
			],
			true,
		]
	]
)


func test_has_commands(params = use_parameters(has_commands_params)):
	_queue._queue = params.commands

	assert_eq(_queue.has_commands, params.expected_result)


class StubAiController:
	extends AiController

	func setup(own_character: Character2D, own_condition: CharacterCondition, ..._args) -> void:
		_character = own_character
		_condition = own_condition
		_agent = NavigationAgent2D.new()
		add_child(_agent)

	func _weigh_target(_key: NodePath, _data: AiTarget, _delta: float) -> void:
		pass

	func _idle() -> void:
		pass

	func _engage_target(_ai_target: AiTarget, _delta: float) -> void:
		pass


class Callback:
	extends RefCounted

	func method(_ac):
		return AiConstants.EndConditions.ACTION_COMPLETED
