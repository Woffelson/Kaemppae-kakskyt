extends Control

@export var button : Resource
@export var ikkuna : Resource

@export_node_path("MarginContainer") var startti_menu
@export_node_path("MarginContainer") var alku_ruutu
@export_node_path("Control") var ruutu
@export_node_path("Button") var aloita
@export_node_path("Button") var b_fin
@export_node_path("Button") var b_eng
@export_node_path("Button") var kuitti

var started = false
var muuttuja = "heja svärje"
var lore = [] #lore contents
var lore_queue = [] #lore in certain order, empty when gone through
var ilmoitus = {}
var ikkunat = [] #keep track of active pop-up windows

#@onready var pop_ikkuna = ikkuna.instantiate()
@onready var starttimenu : MarginContainer = get_node(startti_menu)
@onready var a_screeni : MarginContainer = get_node(alku_ruutu)
@onready var screeni : Control = get_node(ruutu)
@onready var startti : Button = get_node(aloita)
@onready var suomi : Button = get_node(b_fin)
@onready var enkku : Button = get_node(b_eng)
@onready var quitti : Button = get_node(kuitti)

func _ready():
	TranslationServer.set_locale("fi")
	randomize() #ensures different random results
	#seed(0) #ensures same random results with same seed value
	start()

func _process(_delta):
	if started:
		if Input.is_action_just_pressed("ui_accept"):
			var pop_ikkuna = ikkuna.instantiate()
			pop_ikkuna.connect("kloussaa",Callable(self,"close_message"))
			#screeni.
			add_child(pop_ikkuna)
			pop_ikkuna.position = Vector2(randi_range(0,1152-320),randi_range(0,648-160))
			pop_ikkuna.pop_message(pick_lore())
			ikkunat.append(pop_ikkuna)
		if Input.is_action_just_pressed("ui_cancel"):
			start()

func start():
	started = false
	starttimenu.show()
	startti.set_text(tr("START"))
	suomi.set_text(tr("FIN"))
	enkku.set_text(tr("ENG"))
	quitti.set_text(tr("QUIT"))
	startti.grab_focus()

func add_lore(id,tekst,options): #builds the basic blocks of lore messages ("backend")
	var dikki = {}
	dikki["id"] = id
	dikki["txt"] = tekst
	dikki["options"] = options
	lore.append(dikki)

func close_message(suljettava): #does this really happen?
	ikkunat.erase(suljettava)
	#suljettava.queue_free()

func pick_lore():
	#return lore.pick_random() #OG code, pure random, not shuffled
	if lore_queue.size() == 0: #if lore has been gone through, start again
		lore_queue = lore.duplicate()
		lore_queue.shuffle() #shuffled random order
	var pick = lore_queue[0]
	lore_queue.pop_front()
	return pick

func _on_start_button_down(): #after translation set text stuff, not before
	starttimenu.hide() #remove_child queue_free()?
	ilmoitus = {
		"yes": {
			"title": tr("Y"),
			"action": "nappi",
			"act_value": muuttuja
		},
		"no": {
			"title": tr("N"),
			"action": "ebin"
		},
		"ok": {
			"title": tr("OK"),
			"action": "close_message"
		},
	}
	lore.clear()
	add_lore(0,tr("TESTI1"),[ilmoitus["ok"]])
	add_lore(1,tr("TESTI2"),[ilmoitus["yes"],ilmoitus["no"]])
	add_lore(2,tr("TESTI3"),[ilmoitus["yes"],ilmoitus["no"],ilmoitus["ok"]])
	add_lore(3,tr("TESTI4"),[ilmoitus["ok"]])
	add_lore(4,tr("LOREM"),[ilmoitus["ok"]])
	started = true

func _on_fin_button_down():
	TranslationServer.set_locale("fi")
	start()

func _on_eng_button_down():
	TranslationServer.set_locale("en")
	start()

func _on_quit_pressed():
	get_tree().quit()
