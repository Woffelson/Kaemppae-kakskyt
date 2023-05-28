extends Node

var mieliala = 75
var jaksaminen = 75
var popup_gfx = [] #popup window graphics
#END STATS
var decisions = 0
var undecided = 0
var healthy_choices = 0
var sick_choices = 0

func reset():
	mieliala = 75
	jaksaminen = 75
	decisions = 0
	undecided = 0
	healthy_choices = 0
	sick_choices = 0
