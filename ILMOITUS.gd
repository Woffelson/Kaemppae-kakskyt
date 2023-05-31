extends Panel

@export var button : Resource
@export_node_path("Label") var teksti
@export_node_path("HBoxContainer") var nappi_paikka
@export_node_path("ProgressBar") var bar
@export_node_path("Panel") var paneli
@export_node_path("AnimatedSprite2D") var ikoni
@export_node_path("Timer") var ajastin
@export_node_path("Timer") var naputin
@export_node_path("Timer") var animuaika
@export_node_path("Timer") var animuikonaika

var current_lore = {}
var teema = ""
var writing = false
var typewrite_spede = 1
var drag_point = Vector2.ZERO
var output = [0,0] #default output from buttons (mieliala, jaksaminen)
var style = StyleBoxTexture.new()
signal kloussaa(ikkuna,vars)

@onready var txt : Label = get_node(teksti)
@onready var nappipaikka : HBoxContainer = get_node(nappi_paikka)
@onready var aika : ProgressBar = get_node(bar)
@onready var paneeli : Panel = get_node(paneli)
@onready var ikon : AnimatedSprite2D = get_node(ikoni)
@onready var ajastus : Timer = get_node(ajastin)
@onready var write_timer : Timer = get_node(naputin)
@onready var animu : Timer = get_node(animuaika)
@onready var animu_ikon : Timer = get_node(animuikonaika)
@onready var default_txt_size = Vector2.ZERO #teksti.size
@onready var start_pos = Vector2.ZERO

func _ready():
	randomize()
	debuttons() #just in case
	#position = Vector2i(randi_range(0,1152-320),randi_range(0,648-160))
	#print(start_pos)
	await get_tree().process_frame #wait for teema to be set by main...
	if teema == "LATAA":
		z_index = 2 #in front of other windows
		ajastus.set_wait_time(30.0)
		aika.set_max(30)
		var ratio = str(round(float(Global.decisions) / float(Global.decisions+Global.undecided)*100.0))+"% ("
		var result = "\n"+tr("KYKY")+" "+ratio+str(Global.decisions)+"/"+str(Global.undecided)+")\n"
		txt.set_text(txt.get_text() + result + tr("TERVE") + " " + str(Global.healthy_choices) +\
			"\n" + tr("SAIRAS") + " " + str(Global.sick_choices))
	set_gfx(teema)

func _process(_delta):
	if !ajastus.is_stopped(): aika.value = ajastus.wait_time - ajastus.time_left

func set_gfx(tema):
	add_theme_stylebox_override("panel", style)
	var alts = [0,1,3,2]
	var alts_ikon = [0]
	match (tema):
		"ARKI":
			alts = [0,1,3,2,9,19]
			alts_ikon = [0,19]
		"HEMMO":
			alts = [0,1,3,2,19]
			alts_ikon = [5,19]
		"LOHTU":
			alts = [6,8,7]
			alts_ikon = [6,20,21,22]
		"APU":
			alts = [0,1,2,3,9,19]
			alts_ikon = [7,20]
		"SPIRAALI":
			alts = [4,5,15,16,18,19]
			alts_ikon = [10]
		"SEKO":
			alts = [5,9,10,19,20]
			alts_ikon = [8,15,16,17,18,24]
		"ERROR":
			alts = [10]
			alts_ikon = [0,1,2,4]
		"LATAA":
			alts = [0]
#	if Global.mieliala < 25 || Global.jaksaminen < 25:
#		alts.pop_front()
	if Global.mieliala >= 90 && Global.jaksaminen >= 75:
		style.set_texture(Global.popup_gfx[alts[0]])
	else:
		var pick = alts.pick_random()
		var pick_ikon = alts_ikon.pick_random()
		if pick == 10 || pick == 16: animu.start()
		if pick_ikon == 2 || pick_ikon == 8 || pick_ikon == 10 || pick_ikon == 22 || pick_ikon == 24:
			animu_ikon.start()
		style.set_texture(Global.popup_gfx[pick]) #decide randomly from remaining options
		#ikon.texture.set_current_frame(pick_ikon)
		ikon.set_frame(pick_ikon)

func settings(dikki): #creates visible lore stuff ("frontend")
	txt.set_text(dikki["txt"])
	current_lore = dikki #store for later button set (typewriter timer)
	#set_buttons(dikki) #if you want to display buttons immediately

func set_buttons(dikki):
	if dikki["options"].size() > 0: #if there are buttons
		for optio in dikki["options"]:
			add_button(optio)#["title"])
	nappipaikka.get_children()[-1].grab_focus() #0 first -1 last
	if Global.jaksaminen < 25 && (teema == "ARKI" || teema == "HEMMO"):
		nappipaikka.get_children()[0].set_disabled(true)#queue_free() #erases active yes options when exhausted

func add_button(kontsa): #self-explanatory...
	var butt = button.instantiate()
	butt.set_meta("meta",kontsa) #save all content info in button (needed later)
	butt.set_text(kontsa["title"]) #set button text
	nappipaikka.add_child(butt) #add to menu, then determine actions (below)
	if kontsa.get("act_value") == null: #if there is no value, only action
		#print(kontsa["action"])
		butt.button_down.connect(Callable(self,kontsa["action"])) #connect action function
	else: #connect button to its action and value it's affecting
		butt.button_down.connect(Callable(self,kontsa["action"]).bind(kontsa["act_value"]))

func debuttons():
	if get_node_or_null(nappi_paikka) != null: #useless condition? if nappipaikka.get_children().size()>0:
		for butt in nappipaikka.get_children():
			butt.button_down.disconnect(butt.get_meta("meta")["action"]) #!!!
			butt.queue_free()#nappipaikka.remove_child(butt)

func reset_write():
	txt.set_visible_characters(0) #no characters
	write_timer.start()

func pop_message(lore):
	teema = lore["teema"]
	settings(lore) #ilmoitus #pick_lore()
	reset_write()

func close_message(): #outdated solution after refactoring?
#	debuttons()
#	txt.set_text("")
#	paneeli.hide() #remove_child? queue_free()?
	emit_signal("kloussaa",self,output)#current_lore["action"])
	queue_free()

func nappi(juttu): #what happens when a button is pressed
	if juttu[2] != "end": Global.decisions += 1 #made a decision
	if juttu[2] == "healthy": Global.healthy_choices += 1
	elif juttu[2] == "sick": Global.sick_choices += 1
	output = juttu
	close_message()

func timeout_close(): #no decisions, auto-close
	if teema == "LATAA": output = [0,0,"end"]
	else:
		Global.undecided += 1
		output = [-1,0,"ok"] #failed decision decreases mood
	#print("EBIN JUDDU MAGE DÄÄ DOIMII :DDD")
	close_message()

func abs_write(texti): #write letter by letter (longer texts take longer time)
	if texti.visible_characters < texti.get_total_character_count():
		writing = true
		texti.set_visible_characters(texti.get_visible_characters()+typewrite_spede)
	elif texti.visible_characters >= texti.get_total_character_count():
		#texti.set_visible_characters(txt.get_total_character_count())
		texti.set_visible_characters(-1) #make sure every character is visible now
		write_end()

func rel_write(texti): #write portion by portion (all texts take same time)
	if texti.get_visible_ratio() < 1.0:
		writing = true
		texti.set_visible_ratio(texti.get_visible_ratio()+0.05)
	else:
		write_end()

func write_end(): #when writing is finished
	writing = false
	write_timer.stop() #stop writing
	ajastus.start() #start countdown to disappear
	set_buttons(current_lore)

func _on_teksti_resized():
	if txt != null:
		if default_txt_size == Vector2.ZERO:
			default_txt_size = txt.size #initialise default setting
			start_pos = position
			#print(position)
		else:
			var muutos = txt.size.y - default_txt_size.y
			#print(muutos)
			size.y = custom_minimum_size.y + muutos #update size
			#position.y = start_pos.y - muutos/2
			position.y -= round(25.0/2.0) #purkka

func _on_npyttj_timeout(): #typewriter effect
	var tik = $TICK
	if !tik.is_playing(): tik.play()
	abs_write(txt)
	#rel_write(txt)

func _on_gui_input(_event):
	if Input.is_action_pressed("m_left"):
		if drag_point == Vector2.ZERO: drag_point = get_global_mouse_position()  - position
		else:
			#if !writing:
			position = get_global_mouse_position() - drag_point

func _on_ajastin_timeout():
	timeout_close()

func _on_animu_timeout():
	var alts = [16,17]
	if teema == "ERROR" || teema == "SEKO": alts = [10,11,12,13,14]
	style.set_texture(Global.popup_gfx[alts.pick_random()])
	animu.set_wait_time(randf_range(0.01,0.5))

func _on_animu_ikon_timeout():
	var alts_ikon = [2,3]
	if teema == "LOHTU": alts_ikon = [22,23]
	elif teema == "SPIRAALI": alts_ikon = [10,11,12,13,14]
	elif teema == "SEKO":
		if ikon.frame > 20: alts_ikon = [24,25]
		else: alts_ikon = [8,9]
	#ikon.texture.set_current_frame(alts_ikon.pick_random())
	ikon.set_frame(alts_ikon.pick_random())
