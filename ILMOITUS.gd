extends Panel

@export var button : Resource
@export_node_path("Label") var teksti
@export_node_path("HBoxContainer") var nappi_paikka
@export_node_path("Panel") var paneli
@export_node_path("Timer") var ajastin
@export_node_path("Timer") var naputin

var current_lore = {}
var writing = false
var typewrite_spede = 1
var drag_point = Vector2.ZERO
signal kloussaa(aktio)

@onready var txt : Label = get_node(teksti)
@onready var nappipaikka : HBoxContainer = get_node(nappi_paikka)
@onready var paneeli : Panel = get_node(paneli)
@onready var ajastus : Timer = get_node(ajastin)
@onready var write_timer : Timer = get_node(naputin)
@onready var default_txt_size = Vector2.ZERO #teksti.size
@onready var start_pos = Vector2.ZERO

func _ready():
	debuttons() #just in case
	#position = Vector2i(randi_range(0,1152-320),randi_range(0,648-160))
	#print(start_pos)

func _process(_delta):
	pass

func settings(dikki): #creates visible lore stuff ("frontend")
	txt.set_text(dikki["txt"])
	current_lore = dikki #store for later button set (typewriter timer)
	#set_buttons(dikki) #if you want to display buttons immediately

func set_buttons(dikki):
	if dikki["options"].size() > 0: #if there are buttons
		for optio in dikki["options"]:
			add_button(optio)#["title"])
	nappipaikka.get_children()[0].grab_focus()

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
	#if !paneeli.visible:
	#	paneeli.show()
		settings(lore) #ilmoitus #pick_lore()
		reset_write()

func close_message(): #outdated solution after refactoring?
#	debuttons()
#	txt.set_text("")
#	paneeli.hide() #remove_child? queue_free()?
	emit_signal("kloussaa",self)#current_lore["action"])
	queue_free()

func nappi(juttu): #what happens when a button is pressed
	print(juttu)
	close_message()

func ebin():
	print("EBIN JUDDU MAGE DÄÄ DOIMII :DDD")
	close_message()

func abs_write(texti):
	if texti.visible_characters < texti.get_total_character_count():
		writing = true
		texti.set_visible_characters(texti.get_visible_characters()+typewrite_spede)

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
			position.y -= 25/2 #purkka

func _on_npyttj_timeout(): #typewriter effect
	if txt.visible_characters >= txt.get_total_character_count():
		txt.set_visible_characters(-1) #make sure every character is visible now
		#txt.set_visible_characters(txt.get_total_character_count())
		writing = false
		write_timer.stop()
		set_buttons(current_lore)
	else:
		abs_write(txt)
		#txt.set_visible_ratio()

func _on_gui_input(_event):
	if Input.is_action_pressed("m_left"):
		if drag_point == Vector2.ZERO: drag_point = get_global_mouse_position()  - position
		else:
			#if !writing:
			position = get_global_mouse_position() - drag_point
