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