extends Node2D

# warning-ignore:unused_class_variable
var SHOW_HINTS = false

# warning-ignore:unused_class_variable
var player_units = []
# warning-ignore:unused_class_variable
var player = null
var main

func camera_shake(pwr):
	if main:
		main.camera_shake(pwr)

class Item:
	var r 
	var scene
	func _init(r, scene):
		self.r = r
		self.scene = scene

# warning-ignore:unused_class_variable
var Items = {
	'grass': Item.new(15, preload("res://Scenes/grass.tscn")),
	'trunk': Item.new(160, preload("res://Scenes/Obstacles/trunk.tscn")),
	'wall': Item.new(100, preload("res://Scenes/Obstacles/wall.tscn")),
	'bush': Item.new(25, preload("res://Scenes/Obstacles/bush.tscn")),
	'enemy_runner': Item.new(50, preload("res://Scenes/enemy1.tscn")),
	'enemy_gunner': Item.new(50, preload("res://Scenes/enemy2.tscn")),
	'enemy_rocket': Item.new(50, preload("res://Scenes/enemy3.tscn"))
}