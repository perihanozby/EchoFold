class_name PuzzleSession
extends RefCounted
const EngineModel = preload("res://gameplay/systems/puzzle_engine.gd")
var initial: Dictionary
var board: Dictionary
var history: Array = []
var future: Array = []
var actions: Array[String] = []
var redo_actions: Array[String] = []
var moves: int:
	get: return history.size()

func _init(level: Dictionary) -> void:
	initial = level.duplicate(true)
	board = initial.duplicate(true)

func commit(id: String) -> bool:
	var next = EngineModel.fold(board, id)
	if EngineModel.canonical(next) == EngineModel.canonical(board):
		return false
	history.append(board.duplicate(true))
	actions.append(id)
	redo_actions.clear()
	future.clear()
	board = next
	return true

func undo() -> bool:
	if history.is_empty(): return false
	future.append(board.duplicate(true))
	redo_actions.append(actions.pop_back())
	board = history.pop_back()
	return true

func redo() -> bool:
	if future.is_empty(): return false
	history.append(board.duplicate(true))
	actions.append(redo_actions.pop_back())
	board = future.pop_back()
	return true

func reset() -> void:
	board = initial.duplicate(true)
	history.clear()
	future.clear()
	actions.clear()
	redo_actions.clear()
