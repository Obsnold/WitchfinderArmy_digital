extends Node

### NETWORKING
var websocket_url = "127.0.0.1:3000"
var _client = WebSocketClient.new()

# Message Types
enum MSG{LOBBY,WFG}

signal server_disconnected()
signal connected_to_server()
signal conection_failed()
signal data_lobby(data)
signal data_game(data)

# Called when the node enters the scene tree for the first time.
func _ready():
	_client.connect("connection_closed", self, "_server_disconnected")
	_client.connect("connection_error", self, "_connection_failed")
	_client.connect("connection_established", self, "_connected_to_server")
	_client.connect("data_received", self, "_on_data")
	var err = _client.connect_to_url(websocket_url)
	if err != OK:
		Debug.log("Client","Unable to connect")
		set_process(false)
	else:
		Debug.log("Client","Connect OK!")

func _process(delta):
	_client.poll()
	

func send(data):
	var packet: PoolByteArray = JSON.print(data).to_utf8()
	_client.get_peer(1).put_packet(packet)

func _connected_to_server(_protocol: String) -> void:
	Debug.log("Client","_connected_to_server")
	emit_signal("server_disconnected")

func _server_disconnected():
	Debug.log("Client","_server_disconnected")
	emit_signal("server_disconnected")

func _connection_failed():
	Debug.log("Client","_connection_failed")
	emit_signal("server_disconnected")


func _on_data():
	var packet: PoolByteArray = _client.get_peer(1).get_packet()
	var data: Dictionary = JSON.parse(packet.get_string_from_utf8()).result
	match int(int(data.msg_type)):
		MSG.LOBBY:
			emit_signal("data_lobby",data)
		MSG.WFG:
			emit_signal("data_game",data)
		_:	# unknown message
			Debug.log("Client","Unknown message received!!!")
			return
