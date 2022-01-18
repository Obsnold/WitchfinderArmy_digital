extends Node

# lobby subcodes
enum SUB{CREATE,DELETE,JOIN,LEAVE,LIST}

# Menus
enum MENU{MAIN,JOIN,CREATE,NETWORK,NONE}

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
onready var uiPopUpMessage = $ErrorPopup/Message

# holds the instance of the game
var game

func _ready():
	Client.connect("connection_failed", self, "_connection_failed")
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
	uiPopUpMessage.text = "Could not connect to server"
	uiPopUp.popup_centered()
	
func _connected_to_server():
	Debug.log("Lobby","_connected_to_server")
	change_menu(MENU.MAIN)

func _on_data(data):
	Debug.log("Lobby","_on_data")
	match int(data.sub_type):
		SUB.CREATE:
			recv_create_game(int(data.error),int(data.game_id),int(data.user_id))
		SUB.DELETE:
			recv_delete_game(int(data.error))
		SUB.JOIN:
			recv_join_game(int(data.error),int(data.game_id),int(data.user_id),data.player_list)
		SUB.LEAVE:
			recv_leave_game(int(data.error))
		SUB.LIST:
			recv_get_game_list(int(data.error),data.game_list)
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
func recv_create_game(error:int, game_id:int, user_id:int):
	Debug.log("Lobby","recv_create_game error = " +str(error) + " game_id = " + str(game_id) + " user_id = " + str(user_id))
	if error != 0:
		Debug.log("Lobby","Error creating Game! code = " + str(error))
	else:
		send_join_game(str(uiOwnerName.text),str(uiCreatePassword.text),int(game_id))

func recv_delete_game(error:int ):
	Debug.log("Lobby","recv_delete_game error = " +str(error))
	if error != 0:
		Debug.log("Lobby","Error deleting Game! code = " + str(error))
	else:
		game.queuefree()
		change_menu(MENU.MAIN)

func recv_join_game(error:int, game_id:int , user_id:int, player_list:Dictionary):
	Debug.log("Lobby","recv_join_game error = " +str(error) + " game_id = " + str(game_id) + " user_id = " + str(user_id) +"player_list = " + str(player_list))
	if error != 0:
		Debug.log("Lobby","Error joining Game! code = " + str(error))
	else:
		change_menu(MENU.NONE)
		game = load("res://Game.tscn").instance()
		game.set_name(str(game_id))
		game.p_id = user_id
		# have to convert list as after sending keys are now strings instead of ints
		for player in player_list:
			game.player_list[int(player)] = player_list[player]
		add_child(game)
		game.connect("game_ended", self, "_kill_game")
		game.connect("leave_game", self, "_leave_game")
		game.waiting()

func recv_leave_game(error:int ):
	Debug.log("Lobby","recv_leave_game")
	if error != 0:
		Debug.log("Lobby","Error leaving Game! code = " + str(error))
	else:
		game.queue_free()
		change_menu(MENU.MAIN)

func recv_get_game_list(error:int, game_list:Array):
	Debug.log("Lobby","recv_get_game_list")
	if error != 0:
		Debug.log("Lobby","Error listing Game! code = " + str(error))
		return
	Debug.log("Lobby","game list = " + str(game_list))

### UI FUNCTIONS --------------------------------------------------------------
func change_menu(menu):
	uiMainMenu.hide()
	uiJoinGame.hide()
	uiCreateGame.hide()
	uiNetworkSettings.hide()
	match menu:
		MENU.MAIN:
			uiMainMenu.popup_centered()
		MENU.JOIN:
			uiJoinGame.popup_centered()
		MENU.CREATE:
			uiCreateGame.popup_centered()
		MENU.NETWORK:
			uiNetworkSettings.popup_centered()
		MENU.NONE:
			pass
		_:
			Debug.log("Lobby", "Unknown Menu")
			uiMainMenu.popup_centered()

func _on_JoinButton_button_up():
	send_join_game(str(uiPlayerName.text),str(uiJoinPassword.text),int(uiGameID.text))

func _on_CreateButton_button_up():
	send_create_game(str(uiOwnerName.text),str(uiCreatePassword.text),int(uiNoPlayers.text),
					int(uiNoWitchfinders.text),int(uiNoCultists.text),int(uiNoWitches.text))

func _on_BackButton_button_up():
	change_menu(MENU.MAIN)

func _on_JoinGame_button_up():
	change_menu(MENU.JOIN)

func _on_CreateGame_button_up():
	change_menu(MENU.CREATE)

func _on_NetworkSettings_button_up():
	change_menu(MENU.NETWORK)
