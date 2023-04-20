extends Control #MUISTA DEBUTTON KU ESC MENUUN TJSP

@export var button : Resource
@export_node_path("RichTextLabel") var teksti
@export_node_path("HBoxContainer") var nappi_paikka
@export_node_path("Panel") var paneli
@export_node_path("MarginContainer") var startti_menu
@export_node_path("Button") var aloita
@export_node_path("Button") var b_fin
@export_node_path("Button") var b_eng
@export_node_path("Timer") var ajastin

var started = false
var muuttuja = "heja svärje"
var lore = []
var ilmoitus = {}
var current_lore = {}
var writing = false
var typewrite_spede = 1

@onready var txt : RichTextLabel = get_node(teksti)
@onready var nappipaikka : HBoxContainer = get_node(nappi_paikka)
@onready var paneeli : Panel = get_node(paneli)
@onready var starttimenu : MarginContainer = get_node(startti_menu)
@onready var startti : Button = get_node(aloita)
@onready var suomi : Button = get_node(b_fin)
@onready var enkku : Button = get_node(b_eng)
@onready var write_timer : Timer = get_node(ajastin)

func _ready():
	TranslationServer.set_locale("fi")
	randomize() #ensures different random results
	#seed(0) #ensures same random results with same seed value
	paneeli.hide()
	start()

func _process(_delta):
	if started:
		if Input.is_action_just_pressed("ui_accept"):
			pop_message()
		if Input.is_action_just_pressed("ui_cancel"):
			start()

func start():
	started = false
	paneeli.hide()
	starttimenu.show()
	startti.set_text(tr("START"))
	suomi.set_text(tr("FIN"))
	enkku.set_text(tr("ENG"))
	startti.grab_focus()

func settings(dikki): #creates visible lore stuff ("frontend")
	txt.set_text(dikki["txt"])
	current_lore = dikki #store for later button set (typewriter timer)
	#set_buttons(dikki) #if you want to display buttons immediately

func set_buttons(dikki):
	if dikki["options"].size() > 0: #if there are buttons
		for optio in dikki["options"]:
			add_button(optio)#["title"])
	nappipaikka.get_children()[0].grab_focus()

func add_lore(id,tekst,options): #builds the basic blocks of lore messages ("backend")
	var dikki = {}
	dikki["id"] = id
	dikki["txt"] = tekst
	dikki["options"] = options
	lore.append(dikki)

func add_button(kontsa): #self-explanatory...
	var butt = button.instantiate()
	butt.set_meta("meta",kontsa) #save all content info in button (needed later)
	butt.set_text(kontsa["title"]) #set button text
	nappipaikka.add_child(butt) #add to menu, then determine actions (below)
	if kontsa.get("act_value") == null: #if there is no value, only action
		butt.button_down.connect(kontsa["action"]) #connect action function
	else: #connect button to its action and value it's affecting
		butt.button_down.connect(kontsa["action"].bind(kontsa["act_value"]))

func debuttons():
	for butt in nappipaikka.get_children():
		butt.button_down.disconnect(butt.get_meta("meta")["action"]) #!!!
		butt.queue_free()#nappipaikka.remove_child(butt)

func reset_write():
	txt.set_visible_characters(0) #no characters
	write_timer.start()

func pop_message():
	if !paneeli.visible:
		paneeli.show()
		settings(pick_lore())#ilmoitus
		reset_write()

func close_message():
	debuttons()
	txt.set_text("")
	paneeli.hide() #remove_child? queue_free()?

func nappi(_juttu): #what happens when a button is pressed
	#print(juttu)
	close_message()

func ebin():
	#print("EBIN JUDDU MAGE DÄÄ DOIMII :DDD")
	close_message()

func pick_lore():
	return lore.pick_random()

func _on_start_button_down(): #after translation set text stuff, not before
	starttimenu.hide() #remove_child queue_free()?
	ilmoitus = {
		"yes": {
			"title": tr("Y"),
			"action": nappi,
			"act_value": muuttuja
		},
		"no": {
			"title": tr("N"),
			"action": ebin
		},
		"ok": {
			"title": tr("OK"),
			"action": close_message
		},
	}
	lore.clear()
	add_lore(0,tr("TESTI1"),[ilmoitus["ok"]])
	add_lore(1,tr("TESTI2"),[ilmoitus["yes"],ilmoitus["no"]])
	add_lore(2,tr("TESTI3"),[ilmoitus["yes"],ilmoitus["no"],ilmoitus["ok"]])
	add_lore(3,tr("TESTI4"),[ilmoitus["ok"]])
	started = true

func _on_fin_button_down():
	TranslationServer.set_locale("fi")
	start()

func _on_eng_button_down():
	TranslationServer.set_locale("en")
	start()

func _on_timer_timeout(): #typewriter effectt
	if txt.visible_characters >= txt.get_total_character_count():
		writing = false
		write_timer.stop()
		txt.set_visible_characters(-1) #make sure every character is visible now
		set_buttons(current_lore)
	elif txt.visible_characters < txt.get_total_character_count():
		writing = true
		txt.set_visible_characters(txt.get_visible_characters()+typewrite_spede)
