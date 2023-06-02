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
#@export_node_path("Label") var mieli_icon
@export_node_path("TextureRect") var mieli_icon
@export_node_path("TextureRect") var taustaa
@export_node_path("ColorRect") var glits

var dir_popups = DirAccess.open("res://GFX/Popup/")
var dir_taustas = DirAccess.open("res://GFX/Taustat/")
#var mielentila = "arki" #katastrofi, error
var taustatyyppi = "syöveri" #["syöveri","keittiö","huone","ihmiset","silmä","loppu"]
var moodi = 0 #0 one-at-a-time 1 multiple 2 error
var started = false
var ended = false
var muuttuja = [0,0,"ok"]
var lore = {} #lore contents []
var lore_queue = [] #lore in certain order, empty when gone through
var ilmoitus = {}
var ikkunat = [] #keep track of active pop-up windows
var current_tausta = 0
var purkka = 0

signal mielijaxu_signal()

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
@onready var mielicon : TextureRect = get_node(mieli_icon) #Label
@onready var tausta : TextureRect = get_node(taustaa)
@onready var glitch : ColorRect = get_node(glits)

func _ready():
	self.connect("mielijaxu_signal",Callable(self,"update_taustas"))
	self.connect("mielijaxu_signal",Callable(self,"update_stats"))
	tausta.material.set_shader_parameter("color",Vector4(1,1,1,0.5))
	await get_tree().process_frame #useless or not?
	mieli.set_value(Global.mieliala)
	jaxu.set_value(Global.jaksaminen)
	TranslationServer.set_locale("fi")
	randomize() #ensures different random results
	#seed(0) #ensures same random results with same seed value
	purkka = [19,20,23].pick_random()
	#var hojohojo = []
	if dir_taustas:
		for filu in dir_taustas.get_files(): #btw, exported game forgets png locations, so...
			if filu.get_extension() == "import": #seek for import files and remove it from extension
				Global.tausta_gfx.append(load("res://GFX/Taustat/"+filu.replace(".import", ""))) #save assets
				#hojohojo.append("res://GFX/Popup/"+filu)
	if dir_popups:
		for filu in dir_popups.get_files(): #btw, exported game forgets png locations, so...
			if filu.get_extension() == "import": #seek for import files and remove it from extension
				Global.popup_gfx.append(load("res://GFX/Popup/"+filu.replace(".import", ""))) #save assets
				#hojohojo.append("res://GFX/Popup/"+filu)
			#if filu.get_extension() == "png": #seek for import files and remove it from extension
			#	Global.popup_gfx.append(load("res://GFX/Popup/"+filu)) #use this when godot works as should...
	#print(Global.popup_gfx)
#	for hojo in hojohojo:
#		print(hojo)
	start()

func _process(_delta):
	#update_stats() #heavy for every frame, optimise
	#update_taustas() #too heave for every frame, don't do iiiit, optimise this to signal too
	if started:
#		if Input.is_action_just_pressed("ui_accept"):
#			pop_up()
		if Input.is_action_just_pressed("ui_cancel"):
			start()

func start(restart := false):
	glitch.hide()
	ended = false
	moodi = 0
	Global.reset()
	for ikk in screeni.get_children():#kkunat: #fixing......
		if ikk != null: ikk.queue_free()
	ikkunat.clear()
	if !restart: #when started first time or exited to main menu
		timer.stop() #bug fix...?
		screeni.set_mouse_filter(MOUSE_FILTER_IGNORE) #IGNORE (doesn't grab mouse controls to itself)
		started = false
		starttimenu.show()
		startti.set_text(tr("START"))
		suomi.set_text(tr("FIN"))
		enkku.set_text(tr("ENG"))
		quitti.set_text(tr("QUIT"))
		startti.grab_focus()
		taustatyyppi = "syöveri"
		tausta.material.set_shader_parameter("color",Vector4(1,1,1,0.8))
		tausta.material.set_shader_parameter("_max",0.2)
	else: taustatyyppi = ["keittiö","huone","ihmiset"].pick_random()#update_taustatyyppi(true)
	update_stats()
	update_taustas()
	#emit_signal("mielijaxu_signal")

func update_stats(): #mostly sync stats with GUI things
	mieli.set_value(Global.mieliala)
	jaxu.set_value(Global.jaksaminen)
	if jaxu.value < 25: jaxu.set_modulate(Color8(255,0,0)) #⚡️
	else: jaxu.set_modulate(Color8(255,255,255))
	if mieli.value >= 75:# && jaxu.value > 66: #high
		#mielicon.set_text("☺️")
		mielicon.texture.set_current_frame(0)
		moodi = 0
	else:
		moodi = 1
		if mieli.value < 25: #low
			if mieli.value <= 0: #error
				moodi = 2
			elif jaxu.value < 50: mielicon.texture.set_current_frame(2)#mielicon.set_text("☹️️")
			else: mielicon.texture.set_current_frame(9) #super angry >:0
		elif mieli.value > 50: mielicon.texture.set_current_frame(1)#mielicon.set_text("😐️") #mid
		elif jaxu.value < 50: mielicon.texture.set_current_frame(3)
		else: mielicon.texture.set_current_frame(8) #slight anger >:(

func update_taustatyyppi(muutos):
	if !started:
		taustatyyppi = "syöveri"
	elif Global.mieliala <= 0: taustatyyppi = "loppu"
	elif vertailu(90,muutos) > 0:#(Global.mieliala == 90 || Global.mieliala == 75) && nousu:
		taustatyyppi = ["keittiö","huone"].pick_random()
	#elif (Global.mieliala == 75 && !nousu) || Global.mieliala == 50 || (Global.mieliala == 25 && nousu):
	elif vertailu(75,muutos) < 0 || vertailu(25,muutos) > 0 || vertailu(50,muutos) > 0 || vertailu(50,muutos) < 0:
		taustatyyppi = ["keittiö","huone","ihmiset"].pick_random()
		purkka = [19,20,23].pick_random()
	elif vertailu(25,muutos) < 0:#Global.mieliala == 25 && !nousu:
		if Global.jaksaminen >= 50: taustatyyppi = ["keittiö","huone","ihmiset"].pick_random()
		else: taustatyyppi = ["huone","ihmiset","silmä"].pick_random()
	
func vertailu(luku,lisuke):
	if Global.mieliala <= luku && Global.mieliala + lisuke > luku: return 1
	elif Global.mieliala >= luku && Global.mieliala + lisuke < luku: return -1
	else: return 0

func update_taustas(): #["syöveri","keittiö","huone","ihmiset","silmä","loppu"]
	if taustatyyppi == "syöveri":
		current_tausta = 0
	else:
		if Global.mieliala >= 90:
			tausta.material.set_shader_parameter("color",Vector4(1,1,1,1))
			tausta.material.set_shader_parameter("_max",0)
			if taustatyyppi == "keittiö":
				if Global.jaksaminen > 75: current_tausta = 26
				else: current_tausta = 15
			elif taustatyyppi == "huone": current_tausta = randi_range(1,2)
		elif Global.mieliala >= 75:
			tausta.material.set_shader_parameter("color",Vector4(1,1,1,0.9))
			tausta.material.set_shader_parameter("_max",0.1)
			if taustatyyppi == "keittiö": current_tausta = randi_range(17,18)
			elif taustatyyppi == "huone": current_tausta = randi_range(1,2)
		elif Global.mieliala >= 50:
			tausta.material.set_shader_parameter("color",Vector4(1,1,1,0.8))
			tausta.material.set_shader_parameter("_max",0.2)
			if taustatyyppi == "keittiö": current_tausta = purkka #keep fixed!
			elif taustatyyppi == "huone": current_tausta = 3
			elif taustatyyppi == "ihmiset": current_tausta = 8
		elif Global.mieliala >= 25:
			tausta.material.set_shader_parameter("color",Vector4(1,1,1,0.75))
			tausta.material.set_shader_parameter("_max",0.25)
			if taustatyyppi == "keittiö": current_tausta = randi_range(24,25)
			elif taustatyyppi == "huone": current_tausta = 4
			elif taustatyyppi == "ihmiset": current_tausta = randi_range(9,10)
		elif Global.mieliala > 10:
			glitch.hide()
		elif Global.mieliala > 0:
			glitch.show()
			tausta.material.set_shader_parameter("color",Vector4(1,1,1,0.5))
			tausta.material.set_shader_parameter("_max",0.5)
			if taustatyyppi == "keittiö": current_tausta = randi_range(21,22)
			elif taustatyyppi == "huone": current_tausta = randi_range(5,7)
			elif taustatyyppi == "ihmiset": current_tausta = randi_range(11,14)
			elif taustatyyppi == "silmä":
				current_tausta = randi_range(28,29)
				tausta.material.set_shader_parameter("color",Vector4(1,1,1,1))
				tausta.material.set_shader_parameter("_max",0)
		else: #loppu
			glitch.hide()
			tausta.material.set_shader_parameter("color",Vector4(1,1,1,0.8))
			tausta.material.set_shader_parameter("_max",0.2)
			current_tausta = 27
	tausta.set_texture(Global.tausta_gfx[current_tausta])

func add_lore(id,teema,tekst,options): #builds the basic blocks of lore messages ("backend")
	var dikki = {}
	dikki["id"] = id
	dikki["teema"] = teema
	dikki["txt"] = tekst
	dikki["options"] = options
	#lore.append(dikki) #deprecated
	if !lore.has(teema): lore[teema] = [] #make list if there's none
	lore[teema].append(dikki)

func pop_up(final := false):
	var pop_ikkuna = ikkuna.instantiate()
	pop_ikkuna.connect("kloussaa",Callable(self,"closed_popup"))
	screeni.add_child(pop_ikkuna)
	if final: #result message centred
		pop_ikkuna.position = Vector2((1152.0-320.0) / 2.0,(648.0-160.0) / 2.0 + 100) 
		pop_ikkuna.pop_message(pick_lore(lore["LATAA"]))
	else:
		pop_ikkuna.position = Vector2(randi_range(0,1152-320),randi_range(0,648-160))
		pop_ikkuna.pop_message(pick_lore(lore[pick_teema()]))
	ikkunat.append(pop_ikkuna)
	if moodi > 0:
		#if timer.is_stopped():
		timer.start() #generate multiple more based on timer
	else: timer.stop()

func closed_popup(suljettava,vars): #when window gets closed
	ikkunat.erase(suljettava)
	suljettava.queue_free() #memory save?
	if Global.mieliala <= 0: #the last decision
		if !ended:
			pop_up(true)
			ended = true
		elif vars[2] == "end": start(true) #restart teh gaem
	elif moodi == 0 || ikkunat.size() == 0: #always at least one window?
		pop_up()
#	var rise = false
#	if Global.mieliala < Global.mieliala + vars[0]: rise = true #if mood is raising
	Global.mieliala = min(100,max(0,Global.mieliala + vars[0])) #limit changed value between 0-100
	Global.jaksaminen = min(100,max(0,Global.jaksaminen + vars[1]))
	if vars[0] != 0:
		update_taustatyyppi(vars[0])
		emit_signal("mielijaxu_signal")#,[Global.mieliala,Global.jaksaminen])

func pick_teema():
	var options = lore.keys()
	if Global.mieliala > 66: options = ["ARKI", "HEMMO", "LOHTU"]
	elif Global.mieliala < 33:
		if Global.mieliala <= 0: options = ["ERROR"]
		else: options = ["SPIRAALI", "SEKO", "LOHTU", "APU", "ARKI", "HEMMO"]
	else: options = ["SPIRAALI", "LOHTU", "APU", "ARKI", "HEMMO"]
	return options.pick_random()

func pick_lore(loru):
	return loru.pick_random() #OG code, pure random, not shuffled

func pick_lore_shuffled(loru): #currently outdated for this project
	if lore_queue.size() == 0: #if lore has been gone through, start again
		lore_queue = loru.duplicate()
		lore_queue.shuffle() #shuffled random order
	var pick = lore_queue[0]
	lore_queue.pop_front()
	return pick

func multiple_lore(amt,type):
	var loresizesofar = 0#lore.size() ##deprecated functionality!
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
	screeni.set_mouse_filter(MOUSE_FILTER_STOP) #STOP (grabs mouse controls to itself)
	ilmoitus = {
		"yes": {
			"title": tr("Y"),
			"action": "nappi",
			"act_value": muuttuja #kiva: 1,-1 askare -1,-2
		},
		"no": {
			"title": tr("N"),
			"action":  "nappi",#"ebin"
			"act_value": muuttuja#[-1,0]
		},
		"yes_arki": {
			"title": tr("Y"),
			"action": "nappi",
			"act_value": [0,-2,"healthy"]
		},
		"no_arki": {
			"title": tr("N"),
			"action":  "nappi",
			"act_value": [-2,0,"sick"]
		},
		"yes_hemmo": {
			"title": tr("Y"),
			"action": "nappi",
			"act_value": [2,-1,"healthy"]
		},
		"no_hemmo": {
			"title": tr("N"),
			"action":  "nappi",
			"act_value": [-2,0,"sick"]
		},
		"yes_spiraali": {
			"title": tr("Y"),
			"action": "nappi",
			"act_value": [-2,-1,"sick"]
		},
		"no_spiraali": {
			"title": tr("N"),
			"action":  "nappi",
			"act_value": [0,0,"healthy"]
		},
		"ok": {
			"title": tr("OK"),
			"action": "nappi",#close_message
			"act_value": muuttuja
		},
		"end": {
			"title": tr("OK"),
			"action": "nappi",#close_message
			"act_value": [0,0,"end"]
		},
	}
	lore.clear()
	add_lore(0,"LATAA",tr("LATAA"),[ilmoitus["end"]])
	add_lore(0,"TESTI",tr("TESTI1"),[ilmoitus["ok"]])
	add_lore(1,"TESTI",tr("TESTI2"),[ilmoitus["yes"],ilmoitus["no"]])
	add_lore(2,"TESTI",tr("TESTI3"),[ilmoitus["yes"],ilmoitus["no"],ilmoitus["ok"]])
	add_lore(3,"TESTI",tr("TESTI4"),[ilmoitus["ok"]])
	add_lore(0,"SEKO",tr("LOREM"),[ilmoitus["ok"]]) #!!!
	multiple_lore(36,"ARKI")
	multiple_lore(4,"HEMMO")
	multiple_lore(15,"LOHTU")
	multiple_lore(4,"APU")
	multiple_lore(13,"SPIRAALI")
	multiple_lore(17,"SEKO")
	multiple_lore(4,"ERROR")
	started = true
	taustatyyppi = ["keittiö","huone","ihmiset"].pick_random()#update_taustatyyppi(true)
	update_taustas()
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
	var kerroin = 1.0
	if Global.mieliala > 0: #low stats correlate with escalating thoughts:
		#kerroin = (float(Global.mieliala) + float(Global.jaksaminen)) / 100.0 #whatever, cannot do maths
		var summa = (float(Global.mieliala) + float(Global.jaksaminen)) #let's do it hard way...
		if summa > 150: kerroin = 2
		elif summa > 100: kerroin = 1
		elif summa > 50: kerroin = 0.8
		elif summa > 25: kerroin = 0.6
		if Global.mieliala < 10: kerroin = 0.5
	timer.set_wait_time(randf_range(kerroin,kerroin * 4.0))
	if ikkunat.size() < 100: pop_up() #have some limit for pop-ups, will ya?
	if moodi == 2: mielicon.texture.set_current_frame(randi_range(4,7))

func _on_taustatimer_timeout():
	$Taustatimer.set_wait_time(randf_range(0.5,1.0))
	update_stats()
	update_taustas()#tausta_animu()
