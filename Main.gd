extends Node

# lobby subcodes
enum SUB{CREATE,DELETE,JOIN,LEAVE,LIST}

onready var uiSetupWindow = $CenterContainer
onready var uiName = $CenterContainer/TabContainer/BasicSetup/VBoxContainer/Name/Input
onready var uiCreateGame = $CenterContainer/TabContainer/BasicSetup/VBoxContainer/CreateGame/CheckBox
onready var uiGameID  = $CenterContainer/TabContainer/BasicSetup/VBoxContainer/GameID/Input
onready var uiNetIP = $CenterContainer/TabContainer/Network/VBoxContainer/ServerIP/Input
onready var uiNetPort = $CenterContainer/TabContainer/Network/VBoxContainer/ServerPort/Input

var game

func _ready():
	Client.connect("data_lobby", self, "_on_data")

# CLIENT callback functions ----------------------------
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
func send_create_game():
	Debug.log("Lobby","send_create_game")
	var message: Dictionary = {
		msg_type = int(Client.MSG.LOBBY),
		sub_type = int(SUB.CREATE),
		user_name = str(uiName.text),
		password = str("password"),
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

func send_join_game(game_id:int):
	Debug.log("Lobby","send_join_game")
	var message: Dictionary = {
		msg_type = int(Client.MSG.LOBBY),
		sub_type = int(SUB.JOIN),
		game_id = int(game_id),
		user_name = str(uiName.text),
		password = str("password"),
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
		send_join_game(game_id)


func recv_delete_game(error:int ):
	Debug.log("Lobby","recv_delete_game error = " +str(error))
	if error != 0:
		Debug.log("Lobby","Error deleting Game! code = " + str(error))
	else:
		game.queuefree()
		uiSetupWindow.show()

func recv_join_game(error:int, game_id:int , user_id:int, player_list:Dictionary):
	Debug.log("Lobby","recv_join_game error = " +str(error) + " game_id = " + str(game_id) + " user_id = " + str(user_id) +"player_list = " + str(player_list))
	if error != 0:
		Debug.log("Lobby","Error joining Game! code = " + str(error))
	else:
		uiSetupWindow.hide()
		game = load("res://Game.tscn").instance()
		game.set_name(str(game_id))
		game.p_id = user_id
		# have to convert list as after sending keys are now strings instead of ints
		for player in player_list:
			game.player_list[int(player)] = player_list[player]
		add_child(game)
		game.connect("game_ended", self, "_kill_game")
		game.waiting()
		


func recv_leave_game(error:int ):
	Debug.log("Lobby","recv_leave_game")
	if error != 0:
		Debug.log("Lobby","Error leaving Game! code = " + str(error))
	else:
		game.queuefree()
		uiSetupWindow.show()

func recv_get_game_list(error:int, game_list:Array):
	Debug.log("Lobby","recv_get_game_list")
	if error != 0:
		Debug.log("Lobby","Error listing Game! code = " + str(error))
		return
	Debug.log("Lobby","game list = " + str(game_list))

### UI FUNCTIONS --------------------------------------------------------------
func _on_JoinButton_button_up():
	if uiCreateGame.is_pressed():
		send_create_game()
	else:
		send_join_game(int(uiGameID.text))
