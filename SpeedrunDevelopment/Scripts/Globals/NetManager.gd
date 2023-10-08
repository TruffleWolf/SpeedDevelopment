extends Node


signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

const PORT = 4242
const DEFAULT_SERVER_IP = "127.0.0.1"
@onready var max_connections = 3

#all connected peers keyd by ID
var player_list = {}
#IDs in order, p1 is 0 , p2 is 1 etc
var player_order= [null,null,null,null]

var is_host = false

#the current scene in charge of networking things occuring
var net_scene = null

# This is the local player info. This should be modified locally before the connection is made.
# It will be passed to every other peer.
var player_info = {"name": "ANONYMOUS"}

var players_loaded = 0

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connection_success)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	

func join_game(address = ""):
	if address == "":
		address = DEFAULT_SERVER_IP
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address,PORT)
	is_host = false
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	

func host_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT,max_connections)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	is_host = true
	player_list[1] = player_info
	player_order[0] = 1
	player_connected.emit(1,player_info)

func kill_multiplayer_peer():
	multiplayer.multiplayer_peer = null



## When the server decides to start the game from a UI scene, do Lobby.load_game.rpc(filepath)
#@rpc("call_local", "reliable")
#func load_game(game_scene_path):
#	get_tree().change_scene_to_file(game_scene_path)
#
#
## Every peer will call this when they have loaded the game scene.
#@rpc("any_peer", "call_local", "reliable")
#func player_loaded():
#	if multiplayer.is_server():
#		players_loaded += 1
#		if players_loaded == player_list.size():
#			$/root/Game.start_game()
#			players_loaded = 0


func send_player_reliable(pid,func_name,param1 = null):
	_recieve_player_reliable.rpc_id(pid,func_name,param1)

@rpc("any_peer","call_local","reliable",0)
func _recieve_player_reliable(func_name,param1):
	if param1 == null:
		GameManager.current_player.call(func_name)
		return
	GameManager.current_player.call(func_name,param1)

func send_player_unreliable(pid,func_name,param1 = null):
	_recieve_player_unreliable.rpc_id(pid,func_name,param1)

@rpc("any_peer","call_local","unreliable",1)
func _recieve_player_unreliable(func_name,param1):
	if param1 == null:
		GameManager.current_player.call(func_name)
		return
	GameManager.current_player.call(func_name,param1)



func send_manager_reliable(pid,func_name,param1 = null):
	_recieve_manager_reliable.rpc_id(pid,func_name,param1)

@rpc("any_peer","call_local","reliable",0)
func _recieve_manager_reliable(func_name,param1):
	if param1 == null:
		net_scene.call(func_name)
		return
	net_scene.call(func_name,param1)

func send_manager_unreliable(pid,func_name,param1 = null):
	_recieve_manager_unreliable.rpc_id(pid,func_name,param1)

@rpc("any_peer","call_local","unreliable",1)
func _recieve_manager_unreliable(func_name,param1):
	if param1 == null:
		net_scene.call(func_name)
		return
	net_scene.call(func_name,param1)


# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	_register_player.rpc_id(id, player_info)
	if is_host:
		var count = 0
		for p in player_order:
			if p == null:
				player_order[count]= id
				print("assined")
				break
			count += 1
		
		_update_player_order.rpc(player_order)
		print("HostList:"+str(player_order))
	
	

@rpc("any_peer","reliable")
func _update_player_order(who):
	
	player_order = who.duplicate()
	net_scene.order_update()
	print(str(player_order))


@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	player_list[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)
	net_scene.player_connected(new_player_id)
	print("player connected:"+str(new_player_info))
	print("list:"+str(player_list))

func _on_player_disconnected(id):
	player_list.erase(id)
	player_disconnected.emit(id)
	net_scene.player_disconnected(id)

func _on_connection_success():
	var peer_id = multiplayer.get_unique_id()
	player_list[peer_id]=player_info
	player_connected.emit(peer_id,player_info)
	print("connected")

func _on_connection_failed():
	kill_multiplayer_peer()

func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	server_disconnected.emit()
	net_scene.server_disconnected()
