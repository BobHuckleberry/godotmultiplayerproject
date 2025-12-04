extends Node   # Autoload

const PORT := 4242
const MAX_CLIENTS := 8
const WORLD_SCENE_PATH := "res://Scenes/main_scene.tscn"

# Use Copy Path on your player scene in the FileSystem and paste here:
const PLAYER_SCENE: PackedScene = preload("res://Scenes/Player.tscn")

var peer := ENetMultiplayerPeer.new()
var _spawned_player_ids: Array[int] = []


# ----------------- BUTTON ENTRY POINTS -----------------

func create_server() -> void:
	print("Creating server...")
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		push_error("Failed to create server: %s" % err)
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)

	# ensure everyone (including future clients) knows the host exists
	_rpc_spawn_player.rpc(multiplayer.get_unique_id())


func join_server(host: String) -> void:
	print("Joining server at:", host)
	var err := peer.create_client(host, PORT)
	if err != OK:
		push_error("Failed to connect: %s" % err)
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)


# ----------------- SIGNAL CALLBACK -----------------

func _on_peer_connected(id: int) -> void:
	print("Peer connected:", id)

	# broadcast the new player to everyone
	_rpc_spawn_player.rpc(id)

	# backfill existing players for the newcomer
	for existing_id in _spawned_player_ids:
		if existing_id == id:
			continue
		_rpc_spawn_player.rpc_id(id, existing_id)


func _on_connected_to_server() -> void:
	# spawn the client once the connection is ready
	_rpc_spawn_player.rpc(multiplayer.get_unique_id())


# ----------------- WORLD + SPAWN HELPERS -----------------

func _get_world() -> Node:
<<<<<<< HEAD
		# If we're still in the start menu, make sure the actual world is loaded
		var tree := get_tree()

		var world := tree.root.get_node_or_null("Main_Scene")
		if world:
				return world

		# try current scene before forcing a change
		var current := tree.current_scene
		if current and current.name == "Main_Scene":
				return current

		# load the main scene so multiplayer can spawn players
		var err := tree.change_scene_to_file(WORLD_SCENE_PATH)
		if err != OK:
				push_error("Could not change to main scene: %s" % err)
				return tree.root

		return tree.current_scene
=======
	# If we're still in the start menu, make sure the actual world is loaded
	var tree := get_tree()

	var world := tree.root.get_node_or_null("Main_Scene")
	if world:
		return world

	# try current scene before forcing a change
	var current := tree.current_scene
	if current and current.name == "Main_Scene":
		return current

	# load the main scene so multiplayer can spawn players
	var err := tree.change_scene_to_file(WORLD_SCENE_PATH)
	if err != OK:
		push_error("Could not change to main scene: %s" % err)
		return tree.root

	return tree.current_scene
>>>>>>> 387258282477156cb1cea873f11e2c4e81cb6d9c


@rpc("any_peer", "call_local")
func _rpc_spawn_player(id: int) -> void:
	var world := _get_world()
	if world == null:
		return

	if world.get_node_or_null(str(id)):
		return

	# If you later add a Players node, use it here:
	var players := world.get_node_or_null("Players")
	if players == null:
		players = world

	var player := PLAYER_SCENE.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)

	players.add_child(player)
	_spawned_player_ids.append(id)
	print("Spawned player", id, "under", players.name)
