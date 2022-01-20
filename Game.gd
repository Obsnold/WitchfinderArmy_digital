extends Node

const GAME_MSG = 1
enum SUB{CHAT,KILL,PEEK,VOTE,PLAYER_LIST,START,END}
const GAME_END = 0xFF
const GAME_START = 0xFE

enum {WAITING,VOTING,EXECUTING,PEEKING}
var g_state = WAITING
var no_players = 4
var num_of_cultists = 1
var num_of_witches = 1
var num_of_witchfinders = 2
var player_list = {}

enum CARD_TYPE{WITCH, WITCHFINDER, WITCHFINDER_GENERAL, CULTIST, GHOST, NA}

var votes = {}

var p_id: int

signal game_ended
signal leave_game
signal send_msg(data)

onready var uiCardSprite = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/CenterContainer/Sprite
onready var uiName = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/Name
onready var uiGameId = $MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/Game_ID
onready var uiSelectWindow = $MarginContainer/HBoxContainer/Select/VBoxContainer
onready var uiItemList = $MarginContainer/HBoxContainer/Select/VBoxContainer/ItemList
onready var uiItemListTitle = $MarginContainer/HBoxContainer/Select/VBoxContainer/Label
onready var uiItemListButton = $MarginContainer/HBoxContainer/Select/VBoxContainer/Button
onready var uiChatDisplay = $MarginContainer/HBoxContainer/Chat/VBoxContainer/Display
onready var uiChatInput = $MarginContainer/HBoxContainer/Chat/VBoxContainer/Input


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	Client.connect("data_game", self, "_on_data")
	uiCardSprite.texture = load("res://Resources/Cards/back_card.svg")

func waiting():
	Debug.log(str(p_id), "Waiting for all players to join!")
	_send_request_player_list()
	g_state = WAITING
	uiGameId.text = "GAME ID: " + name
	uiItemListTitle.text = "Waiting for players!"
	uiItemListButton.text = "Leave Game"
	#_show_popup(POP.WAITING)


### HELPER FUNCTIONS -------------------------------------------------------
func get_id_from_name(name:String):
	#Debug.log(str(p_id), "get_id_from_name")
	var id = 0
	for player in player_list.keys():
		if player_list[player].name == name:
			id = player
			break
	return id


func get_number_of_living_players():
	#Debug.log(str(p_id), "get_number_of_living_players")
	var num = 0
	for player in player_list.keys():
		if player_list[player].ghost == false:
			num += 1
	return num

func new_general(id:int):
	#Debug.log(str(p_id), "new_general")
	for player in player_list.keys():
		player_list[player].general = false
	player_list[id].general = true
	uiChatDisplay.text += player_list[id].name + " is the new Witchfinder General!" + "\n"
	if id == p_id:
		start_execution()

func _set_player_card_types(): 
	var player_types =[]
	for i in int(num_of_cultists):
		player_types.append(CARD_TYPE.CULTIST)
	
	for i in int(num_of_witches):
		player_types.append(CARD_TYPE.WITCH)
		
	for i in int(num_of_witchfinders):
		player_types.append(CARD_TYPE.WITCHFINDER)
	
	player_types.shuffle()
	
	for player in player_list.keys():
		player_list[player].type = player_types.pop_front()


### GAME FUNCTIONS ---------------------------------------------------------
func start_voting():
	#Debug.log(str(p_id), "start_voting")
	g_state = VOTING
	uiItemList.clear()
	_update_list()
	uiItemListTitle.text = "Vote for Witchfinder General"
	uiItemListButton.text = "VOTE"
	uiItemListButton.show()
	uiSelectWindow.show()

func stop_voting(vote:int):
	#Debug.log(str(p_id), "stop_voting")
	_send_chat_msg("Votes for " + player_list[vote].name)
	_disable_list()
	_send_vote_for(vote)
	uiItemListButton.hide()

func start_execution():
	#Debug.log(str(p_id), "start_execution")
	g_state = EXECUTING
	uiItemList.clear()
	_update_list()
	uiItemListTitle.text = "Select for execution"
	uiItemListButton.text = "EXECUTE"
	uiItemListButton.show()
	uiSelectWindow.show()

func stop_execution(id:int = 0):
	#Debug.log(str(p_id), "stop_execution")
	if id == 0:
		_send_chat_msg( "Fails to Execute anyone")
	else:
		_send_chat_msg( "Executes " + player_list[id].name)
	_send_kill_player(id) 
	_disable_list()
	uiItemListButton.hide()

func start_ghost_peek():
	#Debug.log(str(p_id), "start_ghost_peek")
	g_state = PEEKING
	_update_list()
	uiItemListTitle.text = "Peek at another player"
	uiItemListButton.text = "PEEK"
	uiItemListButton.show()
	uiSelectWindow.show()

func stop_ghost_peek(id:int):
	#Debug.log(str(p_id), "stop_ghost_peek")
	_send_chat_msg( "peeks at " + player_list[id].name)
	uiChatDisplay.text += player_list[id].name + " is a " + CARD_TYPE.keys()[player_list[id].type] + "\n"
	_disable_list()
	uiItemListButton.hide()
	_send_finished_peeking()

func game_start():
	var front
	match int(player_list[p_id].type):
		CARD_TYPE.WITCHFINDER:
			Debug.log(str(p_id),"witchfinder_card")
			front = load("res://Resources/Cards/witchfinder_card.svg")
		CARD_TYPE.WITCHFINDER_GENERAL:
			Debug.log(str(p_id),"witchfinder_general_card")
			front = load("res://Resources/Cards/witchfinder_general_card.svg")
		CARD_TYPE.WITCH:
			Debug.log(str(p_id),"witch_card")
			front = load("res://Resources/Cards/witch_card.svg")
		CARD_TYPE.GHOST:
			Debug.log(str(p_id),"ghost_card")
			front = load("res://Resources/Cards/ghost_card.svg")
		CARD_TYPE.CULTIST:
			Debug.log(str(p_id),"cultist_card")
			front = load("res://Resources/Cards/cultist_card.svg")
		_:
			Debug.log(str(p_id),"NA-------")
			front = load("res://Resources/Cards/back_card.svg")
			return
	uiCardSprite.texture = front
	#_hide_popup()
	start_voting()

func game_end(winner:int):
	#Debug.log(str(p_id), "game_end")
	uiSelectWindow.hide()
	uiChatDisplay.text += CARD_TYPE.keys()[winner] + " WIN!!!!\n"	
	pass

func check_victory():
	#Debug.log(str(p_id), "check_victory")
	var winner = CARD_TYPE.NA
	var is_there_a_cultist = false
	var is_there_a_witch = false
	for player in player_list.keys():
		if player_list[player].ghost == false:
			match int(player_list[player].type):
				CARD_TYPE.WITCH:
					is_there_a_witch = true
				CARD_TYPE.CULTIST:
					is_there_a_cultist = true
				_:
					pass
	if is_there_a_cultist == false:
		## witches and cultists win
		#rpc("victory", CARD_TYPE.WITCHFINDER)
		winner = CARD_TYPE.WITCH
	elif is_there_a_witch == false:
		## witchfinders win
		#rpc("victory", CARD_TYPE.WITCH)
		winner = CARD_TYPE.WITCHFINDER
	
	return winner

### SEND MSG FUCNTIONS -----------------------------------------
func _send_chat_msg(message:String):
	Debug.log(str(p_id), "_send_chat_msg " + str(message))
	var data: Dictionary = {
		msg_type = int(Client.MSG.WFG),
		sub_type = int(SUB.CHAT),
		game_id = int(name),
		user_id = int(p_id),
		message = str(message),
	}
	Client.send(data)
	
func _send_kill_player(id:int):
	Debug.log(str(p_id), "_send_kill_player " + str(id))
	var data: Dictionary = {
		#header = {msg,sub,to,from}
		msg_type = int(Client.MSG.WFG),
		sub_type = int(SUB.KILL),
		game_id = int(name),
		user_id = int(p_id),
		kill_id = int(id),
	}
	Client.send(data)
	
func _send_finished_peeking():
	Debug.log(str(p_id), "_send_finished_peeking")
	var data: Dictionary = {
		msg_type = int(Client.MSG.WFG),
		sub_type = int(SUB.PEEK),
		game_id = int(name),
	}
	Client.send(data)
	
func _send_vote_for(vote:int):
	Debug.log(str(p_id), "_send_vote_for " + str(vote))
	var data: Dictionary = {
		msg_type = int(Client.MSG.WFG),
		sub_type = int(SUB.VOTE),
		game_id = int(name),
		user_id = int(p_id),
		vote_id = int(vote)
	}
	Client.send(data)
	
func _send_request_player_list():
	Debug.log(str(p_id), "_send_request_player_list")
	var data: Dictionary = {
		msg_type = int(Client.MSG.WFG),
		sub_type = int(SUB.PLAYER_LIST),
		game_id = int(name),
	}
	Client.send(data)
	
func _send_update_player_list():
	Debug.log(str(p_id), "_send_update_player_list")
	var data: Dictionary = {
		msg_type = int(Client.MSG.WFG),
		sub_type = int(SUB.PLAYER_LIST),
		game_id = int(name),
		list = player_list
	}
	Client.send(data)
	
func _send_start_game():
	Debug.log("WFG " + name, "PLAYER_LIST")
	var data: Dictionary = {
		msg_type = Client.MSG.WFG,
		sub_type = SUB.START,
		game_id = int(name),
	}
	Client.send(data)
	
### RECEIVE MSG FUNCTIONS --------------------------------------
func _rcv_msg_chat(id:int ,message: String):
	Debug.log(str(p_id), "_rcv_msg_chat " + str(id) + ": " + str(message))
	uiChatDisplay.text += player_list[id].name + ": " + message + "\n"

func _rcv_kill_player(id:int):
	Debug.log(str(p_id), "kill_player " + str(id))
	player_list[id].ghost = true
	var winner = check_victory()
	if winner != CARD_TYPE.NA:
		#game over
		game_end(winner)
	else:
		if id == p_id:
			start_ghost_peek()

func _rcv_finished_peeking():
	Debug.log(str(p_id), "finished_peeking")
	if player_list[p_id].ghost == false:
		start_voting()

func _rcv_vote_for(id,vote):
	Debug.log(str(p_id), "vote_for "  + str(id) + ": " + str(vote))
	if vote != 0:
		votes[id] = vote
		#Debug.log(str(p_id), str(votes.size()) + " number of votes")
		#Debug.log(str(p_id), str(get_number_of_living_players()) + " get_number_of_living_players")
		if votes.size() == get_number_of_living_players():
			var temp = {}
			for player in player_list.keys():
				temp[player] = 0
			for player in votes.keys():
				temp[votes[player]] += 1
			var new_witchfinder_general = 0
			var temp_score = 0
			for player in temp.keys():
				if temp_score < temp[player]:
					temp_score = temp[player]
					new_witchfinder_general = player
			new_general(new_witchfinder_general)
			votes.clear()

func _rcv_start_game():
	Debug.log(str(p_id), "_rcv_start_game")
	game_start()


func _rcv_update_player_list(list):
	Debug.log(str(p_id), "_rcv_update_player_list" + str(list) )
	# have to convert list as after sending keys are now strings instead of ints
	player_list = {}
	for player in list:
		player_list[int(player)] = list[player]
	if g_state == WAITING:
		uiName.text = player_list[p_id].name
		_update_list()
		if player_list.size() == no_players && str(p_id) == str(name):
			
			#start game
			_set_player_card_types()
			_send_update_player_list()
			_send_start_game()
		

func _rcv_end_game():
	Debug.log(str(p_id), "_rcv_end_game")
	emit_signal("game_ended")


### ----------------------------------------------------
func _on_data(data):
	Debug.log(str(p_id), "_on_data " + str(p_id) + " " + str(data.sub_type))
	match int(data.sub_type):
		SUB.CHAT:	# chat message
			_rcv_msg_chat(int(data.user_id),str(data.message))
		SUB.KILL:	# player has been executed
			_rcv_kill_player(int(data.kill_id))
		SUB.PEEK:	# player has finished peeking
			_rcv_finished_peeking()
		SUB.VOTE:	# a player has voted
			_rcv_vote_for(int(data.user_id),int(data.vote_id))
		SUB.PLAYER_LIST:	# new player list received
			_rcv_update_player_list(data.list)
		SUB.START:	# game start
			_rcv_start_game()
		SUB.END:	# game end
			_rcv_end_game()
		_:	# unknown message
			Debug.log(str(p_id), "Unknown message received!!! " + str(data.sub_type))
			return


### UI FUNCTIONS ---------------------------------------
func _on_SendButton_button_up():
	_send_chat_msg(uiChatInput.text)
	uiChatInput.text = ""

func _on_Button_button_up():
	var select = uiItemList.get_selected_items()
	match g_state:
		WAITING:
			emit_signal("leave_game")
		VOTING:
			if select.size() > 0:
				var id = get_id_from_name(uiItemList.get_item_text(select[0]))
				stop_voting(id)
		EXECUTING:
			if select.size() > 0:
				var id = get_id_from_name(uiItemList.get_item_text(select[0]))
				stop_execution(id)
		PEEKING:
			if select.size() > 0:
				var id = get_id_from_name(uiItemList.get_item_text(select[0]))
				stop_ghost_peek(id)
		_:
			pass

func _disable_list():
	uiItemList.unselect_all()
	for num in uiItemList.get_item_count():
		uiItemList.set_item_disabled(num,true)

func _enable_list():
	for num in uiItemList.get_item_count():
		uiItemList.set_item_enabled(num,true)

func _update_list():
	uiItemList.clear()
	match g_state:
		EXECUTING:
			for player in player_list.keys():
				if player_list[player].general == true or player_list[player].ghost == true:
					_add_player_to_list(player,false)
				else:
					_add_player_to_list(player,true)
		VOTING,PEEKING:
			for player in player_list.keys():
				if player_list[player].ghost == true:
					_add_player_to_list(player,false)
				else:
					_add_player_to_list(player,true)
		_:
			for player in player_list.keys():
				_add_player_to_list(player,false)
			pass
		
func _add_player_to_list(player:int,enabled:bool):
	var name_tag = player_list[player].name
	if(g_state != WAITING):
		if (player_list[p_id].type == player_list[player].type):
			match int(player_list[player].type):
				CARD_TYPE.WITCH:
					name_tag += " (Witch)"
				CARD_TYPE.CULTIST:
					name_tag += " (Cultist)"
		if player_list[player].ghost == true:
			name_tag += " (Ghost)"
		if player_list[player].general == true:
			name_tag += " (General)"
	uiItemList.add_item(name_tag,null,enabled)
