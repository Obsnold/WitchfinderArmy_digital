extends Node

# lobby subcodes
enum SUB{CREATE,DELETE,JOIN,LEAVE,LIST}

# Menus
enum MENU{LOADING,MAIN,JOIN,CREATE,NETWORK,NONE}

# Error Codes
enum ERROR{NO_ERROR,NO_SUCH_GAME_ID,CANNOT_JOIN_GAME,INVALID_PASSWORD}

# Main Menu UI
onready var uiMainMenu = $MainMenu
onready var JoinMenuButton = $MainMenu/MarginContainer/VBoxContainer/JoinGame
onready var CreateMenuButton = $MainMenu/MarginContainer/VBoxContainer/CreateGame
onready var NetworkMenuButton = $MainMenu/MarginContainer/VBoxContainer/NetworkSettings

# Join Game UI
onready var uiJoinGame = $JoinGame
onready var uiPlayerName = $JoinGame/MarginContainer/VBoxContainer/Name/Input
onready var uiGameID = $JoinGame/MarginContainer/VBoxContainer/GameID/Input
onready var uiJoinButton = $JoinGame/MarginContainer/VBoxContainer/JoinButton
onready var uiJoinBackButton = $JoinGame/MarginContainer/VBoxContainer/BackButton
onready var uiJoinPassword = $JoinGame/MarginContainer/VBoxContainer/Password/Input

# Create Game UI
onready var uiCreateGame = $CreateGame
onready var uiOwnerName = $CreateGame/MarginContainer/VBoxContainer/Name/Input
onready var uiNoPlayers = $CreateGame/MarginContainer/VBoxContainer/NoPlayers/Input
onready var uiNoWitches = $CreateGame/MarginContainer/VBoxContainer/Witches/Input
onready var uiNoWitchfinders = $CreateGame/MarginContainer/VBoxContainer/Witchfinders/Input
onready var uiNoCultists = $CreateGame/MarginContainer/VBoxContainer/Cultists/Input
onready var uiCreateButton = $CreateGame/MarginContainer/VBoxContainer/CreateButton
onready var uiCreateBackButton = $CreateGame/MarginContainer/VBoxContainer/BackButton
onready var uiCreatePassword = $CreateGame/MarginContainer/VBoxContainer/Password/Input

# Network Settings UI
onready var uiNetworkSettings = $NetworkSettings
onready var uiNetIP = $NetworkSettings/MarginContainer/VBoxContainer/ServerIP/Input
onready var uiNetPort = $NetworkSettings/MarginContainer/VBoxContainer/ServerPort/Input
onready var uiNetBackButton = $NetworkSettings/MarginContainer/VBoxContainer/BackButton

# Error PopUp UI
onready var uiPopUp = $ErrorPopup
onready var uiPopUpMessage = $ErrorPopup/MarginContainer/Message

onready var uiLoading = $Loading

onready var uiTitle = $Title

# holds the instance of the game
var game

func _ready():
	change_menu(MENU.LOADING)
	Client.connect("connection_error", self, "_connection_failed")
	Client.connect("connected_to_server", self, "_connected_to_server")
	Client.connect("data_lobby", self, "_on_data")
	if Client.connect_to_server() == false:
		uiPopUpMessage.text = "Cannot Connect To Server!\nTry refreshing Page"
		uiPopUp.popup_centered()

func _kill_game():
	game.queue_free()
	change_menu(MENU.MAIN)

func _leave_game():
	send_leave_game(int(game.name))

# CLIENT callback functions ----------------------------
func _connection_failed():
	Debug.log("Lobby","_connection_failed")
	uiPopUpMessage.text = "Could not connect to server!\nTry refreshing Page"
	uiPopUp.popup_centered()
	
func _connected_to_server():
	Debug.log("Lobby","_connected_to_server")
	change_menu(MENU.MAIN)

func _on_data(data):
	Debug.log("Lobby","_on_data")
	if int(data.error) != ERROR.NO_ERROR:
		Debug.log("Lobby","Error Message recieved")
		handle_error(int(data.error))
		return
	match int(data.sub_type):
		SUB.CREATE:
			recv_create_game(int(data.game_id),int(data.user_id))
		SUB.DELETE:
			recv_delete_game()
		SUB.JOIN:
			recv_join_game(int(data.game_id),int(data.user_id),data.player_list)
		SUB.LEAVE:
			recv_leave_game()
		SUB.LIST:
			recv_get_game_list(data.game_list)
		_:	# unknown message
			Debug.log("Lobby","Unknown message received!!!")
			return

### GAME FUNCTIONS ------------------------------------------------------------
func send_create_game(player_name:String, password:String, player_count:int, witchfinders:int, cultists:int, witches:int):
	Debug.log("Lobby","send_create_game")
	var message: Dictionary = {
		msg_type = int(Client.MSG.LOBBY),
		sub_type = int(SUB.CREATE),
		user_name = str(player_name),
		password = str(password),
		witchfinders = int(witchfinders),
		cultists = int(cultists),
		witches = int(witches), 
		player_count = int(player_count),
	}
	Client.send(message)
	
func send_delete_game(game_id:int):
	Debug.log("Lobby","send_delete_game")
	var message: Dictionary = {
		msg_type = int(Client.MSG.LOBBY),
		sub_type = int(SUB.DELETE),
		game_id = int(game_id),
	}
	Client.send(message)

func send_join_game(player_name:String, password:String, game_id:int):
	Debug.log("Lobby","send_join_game")
	var message: Dictionary = {
		msg_type = int(Client.MSG.LOBBY),
		sub_type = int(SUB.JOIN),
		game_id = int(game_id),
		user_name = str(player_name),
		password = str(password),
	}
	Client.send(message)

func send_leave_game(game_id:int):
	Debug.log("Lobby","send_leave_game")
	var message: Dictionary = {
		msg_type = int(Client.MSG.LOBBY),
		sub_type = int(SUB.LEAVE),
		game_id = int(game_id),
	}
	Client.send(message)

func send_get_game_list():
	Debug.log("Lobby","send_get_game_list")
	var message: Dictionary = {
		msg_type = int(Client.MSG.LOBBY),
		sub_type = int(SUB.LIST)
	}
	Client.send(message)

### RECV FUNCTIONS ------------------------------------------------------------
func recv_create_game(game_id:int, user_id:int):
	Debug.log("Lobby","recv_create_game game_id = " + str(game_id) + " user_id = " + str(user_id))
	send_join_game(str(uiOwnerName.text),str(uiCreatePassword.text),int(game_id))

func recv_delete_game():
	Debug.log("Lobby","recv_delete_game")
	game.queuefree()
	change_menu(MENU.MAIN)

func recv_join_game(game_id:int , user_id:int, player_list:Dictionary):
	Debug.log("Lobby","recv_join_game game_id = " + str(game_id) + " user_id = " + str(user_id) +"player_list = " + str(player_list))
	change_menu(MENU.NONE)
	game = load("res://Game.tscn").instance()
	game.set_name(str(game_id))
	game.p_id = user_id
	if user_id == game_id:
		game.password = str(uiCreatePassword.text)
	else:
		game.password = str(uiJoinPassword.text)
	# have to convert list as after sending keys are now strings instead of ints
	for player in player_list:
		game.player_list[int(player)] = player_list[player]
	add_child(game)
	game.connect("game_ended", self, "_kill_game")
	game.connect("leave_game", self, "_leave_game")
	game.waiting()

func recv_leave_game():
	Debug.log("Lobby","recv_leave_game")
	game.queue_free()
	change_menu(MENU.MAIN)

func recv_get_game_list(game_list:Array):
	Debug.log("Lobby","recv_get_game_list")
	Debug.log("Lobby","game list = " + str(game_list))

### UI FUNCTIONS --------------------------------------------------------------
func change_menu(menu):
	Debug.log("Lobby","change_menu")
	uiMainMenu.hide()
	uiJoinGame.hide()
	uiCreateGame.hide()
	uiNetworkSettings.hide()
	uiLoading.hide()
	match menu:
		MENU.LOADING:
			uiLoading.popup_centered()
			uiTitle.show()
		MENU.MAIN:
			uiMainMenu.popup_centered()
			uiTitle.show()
		MENU.JOIN:
			uiJoinGame.popup_centered()
			uiTitle.show()
		MENU.CREATE:
			uiCreateGame.popup_centered()
			uiTitle.show()
		MENU.NETWORK:
			uiNetworkSettings.popup_centered()
			uiTitle.show()
		MENU.NONE:
			uiTitle.hide()
			pass
		_:
			Debug.log("Lobby", "Unknown Menu")
			uiMainMenu.popup_centered()

func handle_error(err_code:int):
	uiPopUpMessage.text = str(ERROR.keys()[err_code])
	uiPopUp.popup_centered()

func _on_BackButton_button_up():
	Debug.log("Lobby","BackButton")
	change_menu(MENU.MAIN)

func _on_JoinGame_button_up():
	change_menu(MENU.JOIN)

func _on_CreateGame_button_up():
	change_menu(MENU.CREATE)

func _on_NetworkSettings_button_up():
	change_menu(MENU.NETWORK)

# join menu controlls
func _on_JoinButton_button_up():
	change_menu(MENU.LOADING)
	send_join_game(str(uiPlayerName.text),str(uiJoinPassword.text),int(uiGameID.text))

func _on_player_name_text_changed(new_text):
	check_join_button_enable()

func _on_game_id_text_changed(new_text):
	check_join_button_enable()

func check_join_button_enable():
	if uiPlayerName.text == "" || uiGameID.text == "":
		uiJoinButton.disabled = true
		
	if uiPlayerName.text != "" && uiGameID.text != "":
		uiJoinButton.disabled = false

#Create game menu buttons
func _on_OwnerName_text_changed(new_text):
	check_create_button_enable()
	
func _on_NoPlayers_value_changed(value):
	match int(uiNoPlayers.value):
		4:
			uiNoWitchfinders.value = 2
			uiNoWitches.value = 1
			uiNoCultists.value = 1
		5:
			uiNoWitchfinders.value = 2
			uiNoWitches.value = 2
			uiNoCultists.value = 1
		6:
			uiNoWitchfinders.value = 2
			uiNoWitches.value = 2
			uiNoCultists.value = 2
		7:
			uiNoWitchfinders.value = 3
			uiNoWitches.value = 2
			uiNoCultists.value = 2
		8:
			uiNoWitchfinders.value = 4
			uiNoWitches.value = 2
			uiNoCultists.value = 2
		9:
			uiNoWitchfinders.value = 5
			uiNoWitches.value = 2
			uiNoCultists.value = 2
		10:
			uiNoWitchfinders.value = 6
			uiNoWitches.value = 2
			uiNoCultists.value = 2
		11:
			uiNoWitchfinders.value = 6
			uiNoWitches.value = 3
			uiNoCultists.value = 2
		12:
			uiNoWitchfinders.value = 6
			uiNoWitches.value = 3
			uiNoCultists.value = 3
		13:
			uiNoWitchfinders.value = 7
			uiNoWitches.value = 3
			uiNoCultists.value = 3
		14:
			uiNoWitchfinders.value = 8
			uiNoWitches.value = 3
			uiNoCultists.value = 3
		15:
			uiNoWitchfinders.value = 8
			uiNoWitches.value = 4
			uiNoCultists.value = 3
		16:
			uiNoWitchfinders.value = 8
			uiNoWitches.value = 4
			uiNoCultists.value = 4
		17:
			uiNoWitchfinders.value = 9
			uiNoWitches.value = 4
			uiNoCultists.value = 4
		18:
			uiNoWitchfinders.value = 10
			uiNoWitches.value = 4
			uiNoCultists.value = 4
		19:
			uiNoWitchfinders.value = 10
			uiNoWitches.value = 5
			uiNoCultists.value = 4
		20:
			uiNoWitchfinders.value = 10
			uiNoWitches.value = 5
			uiNoCultists.value = 5
		21:
			uiNoWitchfinders.value = 11
			uiNoWitches.value = 5
			uiNoCultists.value = 5
		22:
			uiNoWitchfinders.value = 12
			uiNoWitches.value = 5
			uiNoCultists.value = 5
		23:
			uiNoWitchfinders.value = 12
			uiNoWitches.value = 6
			uiNoCultists.value = 5
		24:
			uiNoWitchfinders.value = 12
			uiNoWitches.value = 6
			uiNoCultists.value = 6
	check_create_button_enable()

func _on_Witchfinders_value_changed(value):
	if (uiNoWitchfinders.value + uiNoCultists.value + uiNoWitches.value) > uiNoPlayers.value:
		uiNoWitchfinders.value = value - 1
	check_create_button_enable()

func _on_Witches_value_changed(value):
	if (uiNoWitchfinders.value + uiNoCultists.value + uiNoWitches.value) > uiNoPlayers.value:
		uiNoWitches.value = value - 1
	check_create_button_enable()

func _on_Cultists_value_changed(value):
	if (uiNoWitchfinders.value + uiNoCultists.value + uiNoWitches.value) > uiNoPlayers.value:
		uiNoCultists.value = value - 1
	check_create_button_enable()

func _on_CreateButton_button_up():
	change_menu(MENU.LOADING)
	send_create_game(str(uiOwnerName.text),str(uiCreatePassword.text),int(uiNoPlayers.value),
			int(uiNoWitchfinders.value),int(uiNoCultists.value),int(uiNoWitches.value))
		

func check_create_button_enable():
	if (uiNoWitchfinders.value + uiNoCultists.value + uiNoWitches.value) < uiNoPlayers.value || uiOwnerName.text == "":
		uiCreateButton.disabled = true
		
	if (uiNoWitchfinders.value + uiNoCultists.value + uiNoWitches.value) == uiNoPlayers.value && uiOwnerName.text != "":
		uiCreateButton.disabled = false








