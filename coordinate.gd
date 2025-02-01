class_name Coordinate
extends Node
var x: int = 0
var y: int = 0
var elevation: int = 0
var temperature: int = 0

func _init(inputX: int, inputY: int):
	x = inputX
	y = inputY
	temperature = 26 - abs(inputY - 26)
	
func incrementElevation():
	elevation += 1

func decrementElevation():
	elevation -= 1
	
func readElevation() -> int:
	return elevation
	
func readTemperature() -> int:
	return temperature
