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
@export_node_path("Timer") var timeri
@export_node_path("ProgressBar") var mielibar
@export_node_path("ProgressBar") var jaxubar
@export_node_path("Label") var mieli_icon

var dir_popups = DirAccess.open("res://GFX/Popup/")
#var mieliala = 50
#var jaksaminen = 50
var mielentila = "arki" #katastrofi, error
var moodi = 2 #0 error 1 one-at-a-time 2 multiple
var started = false
var muuttuja = "heja svärje"
var muuttuja_y = [0,0]
var muuttuja_n = [0,0]
var lore = [] #lore contents
var lore_queue = [] #lore in certain order, empty when gone through
var ilmoitus = {}
var ikkunat = [] #keep track of active pop-up windows

@onready var starttimenu : MarginContainer = get_node(startti_menu)
@onready var a_screeni : MarginContainer = get_node(alku_ruutu)
@onready var screeni : Control = get_node(ruutu)
@onready var startti : Button = get_node(aloita)
@onready var suomi : Button = get_node(b_fin)
@onready var enkku : Button = get_node(b_eng)
@onready var quitti : Button = get_node(kuitti)
@onready var timer : Timer = get_node(timeri)
@onready var mieli : ProgressBar = get_node(mielibar)
@onready var jaxu : ProgressBar = get_node(jaxubar)
@onready var mielicon : Label = get_node(mieli_icon)

func _ready():
	if dir_popups:
		for filu in dir_popups.get_files():
			if filu.get_extension() == "png": #exclude import files and other crap
				Global.popup_gfx.append(filu) #save assets
	print(Global.popup_gfx[20])
	TranslationServer.set_locale("fi")
	randomize() #ensures different random results
	#seed(0) #ensures same random results with same seed value
	start()

func _process(_delta):
	update_stats()
	if started:
#		if Input.is_action_just_pressed("ui_accept"):
#			pop_up()
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

func update_stats(): #mostly sync stats with GUI things
	mieli.set_value(Global.mieliala)
	jaxu.set_value(Global.jaksaminen)
	if mieli.value > 66: mielicon.set_text("☺️")
	elif mieli.value < 33: mielicon.set_text("☹️️")
	else: mielicon.set_text("😐️")

func add_lore(id,teema,tekst,options): #builds the basic blocks of lore messages ("backend")
	var dikki = {}
	dikki["id"] = id
	dikki["teema"] = teema
	dikki["txt"] = tekst
	dikki["options"] = options
	lore.append(dikki)

func pop_up():
	var pop_ikkuna = ikkuna.instantiate()
	pop_ikkuna.connect("kloussaa",Callable(self,"closed_popup"))
	#screeni.
	add_child(pop_ikkuna)
	pop_ikkuna.position = Vector2(randi_range(0,1152-320),randi_range(0,648-160))
	pop_ikkuna.pop_message(pick_lore())
	ikkunat.append(pop_ikkuna)
	if moodi > 1: timer.start() #generate multiple more based on timer

func closed_popup(suljettava,vars): #when window gets closed
	ikkunat.erase(suljettava)
	if moodi == 1 || ikkunat.size() == 0: #always at least one window?
		pop_up()
	Global.mieliala = min(100,max(0,Global.mieliala + vars[0])) #limit between 0-100
	Global.jaksaminen = min(100,max(0,Global.jaksaminen + vars[1]))
	#print(vars)
	#suljettava.queue_free()

func pick_lore():
	#return lore.pick_random() #OG code, pure random, not shuffled
	if lore_queue.size() == 0: #if lore has been gone through, start again
		lore_queue = lore.duplicate()
		lore_queue.shuffle() #shuffled random order
	var pick = lore_queue[0]
	lore_queue.pop_front()
	return pick

func multiple_lore(amt,type):
	var loresizesofar = lore.size()
	for i in amt + 1: #+1 makes amt inclusive
		var tmp_txt = type + str(i)
		if type == "ARKI": 
			add_lore(loresizesofar + i,type,tr(tmp_txt),[ilmoitus["yes_arki"],ilmoitus["no_arki"]])
		elif type == "HEMMO":
			add_lore(loresizesofar + i,type,tr(tmp_txt),[ilmoitus["yes_hemmo"],ilmoitus["no_hemmo"]])
		elif type == "SPIRAALI": 
			add_lore(loresizesofar + i,type,tr(tmp_txt),[ilmoitus["yes_spiraali"],ilmoitus["no_spiraali"]])
		else:#if type == "LOHTU" || type == "SEKO":
			add_lore(loresizesofar + i,type,tr(tmp_txt),[ilmoitus["ok"]])

func _on_start_button_down(): #after translation set text stuff, not before
	starttimenu.hide() #remove_child queue_free()?
	ilmoitus = {
		"yes": {
			"title": tr("Y"),
			"action": "nappi",
			"act_value": muuttuja_y #kiva: 1,-1 askare -1,-2
		},
		"no": {
			"title": tr("N"),
			"action":  "nappi",#"ebin"
			"act_value": muuttuja_n#[-1,0]
		},
		"yes_arki": {
			"title": tr("Y"),
			"action": "nappi",
			"act_value": [-1,-2]
		},
		"no_arki": {
			"title": tr("N"),
			"action":  "nappi",
			"act_value": [-2,0]
		},
		"yes_hemmo": {
			"title": tr("Y"),
			"action": "nappi",
			"act_value": [1,-1]
		},
		"no_hemmo": {
			"title": tr("N"),
			"action":  "nappi",
			"act_value": [-2,0]
		},
		"yes_spiraali": {
			"title": tr("Y"),
			"action": "nappi",
			"act_value": [-2,-1]
		},
		"no_spiraali": {
			"title": tr("N"),
			"action":  "nappi",
			"act_value": [0,0]
		},
		"ok": {
			"title": tr("OK"),
			"action": "close_message"
		},
	}
	lore.clear()
	add_lore(0,"test",tr("TESTI1"),[ilmoitus["ok"]])
	add_lore(1,"test",tr("TESTI2"),[ilmoitus["yes"],ilmoitus["no"]])
	add_lore(2,"test",tr("TESTI3"),[ilmoitus["yes"],ilmoitus["no"],ilmoitus["ok"]])
	add_lore(3,"test",tr("TESTI4"),[ilmoitus["ok"]])
	add_lore(4,"random",tr("LOREM"),[ilmoitus["ok"]])
	multiple_lore(7,"ARKI")
	multiple_lore(4,"HEMMO")
	multiple_lore(14,"LOHTU")
	multiple_lore(10,"SPIRAALI")
	multiple_lore(8,"SEKO")
	started = true
	pop_up()

func _on_fin_button_down():
	TranslationServer.set_locale("fi")
	start()

func _on_eng_button_down():
	TranslationServer.set_locale("en")
	start()

func _on_quit_pressed():
	get_tree().quit()

func _on_timer_timeout():
	timer.set_wait_time(randf_range(1.0,5.0))
	if lore.size() > 100: pop_up() #have some limit for pop-ups, will ya?
