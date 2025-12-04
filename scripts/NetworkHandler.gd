extends Node   # Autoload

const PORT := 4242
const MAX_CLIENTS := 8
const WORLD_SCENE_PATH := "res://Scenes/main_scene.tscn"

# Use Copy Path on your player scene in the FileSystem and paste here:
const PLAYER_SCENE: PackedScene = preload("res://Scenes/Player.tscn")

var peer := ENetMultiplayerPeer.new()
var _spawned_player_ids: Array[int] = []
const SPAWNER_PATH := "MultiplayerSpawner"


func _ready() -> void:
	# When the main scene (and its MultiplayerSpawner) loads, configure it immediately.
	get_tree().node_added.connect(_on_node_added)


# ----------------- BUTTON ENTRY POINTS -----------------
func create_server() -> void:
	print("Creating server...")
	_teardown_session()  # allow restarting in the same process

	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		push_error("Failed to create server: %s" % err)
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)

	# make sure the world is loaded and spawn the host
	_spawn_player(multiplayer.get_unique_id())


func join_server(host: String) -> void:
	print("Joining server at:", host)
	_teardown_session()  # if we were hosting, cleanly stop and reconnect as client

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

	# only the server should create player nodes; spawner will replicate them
	if multiplayer.is_server():
		_spawn_player(id)


func _on_connected_to_server() -> void:
	# ensure the world is loaded so the server can replicate spawned players
	var world := _get_world()
	_setup_spawner(world)


# ----------------- WORLD + SPAWN HELPERS -----------------
func _get_world() -> Node:
	# If we're still in the start menu, make sure the actual world is loaded
	var tree := get_tree()

	var world := tree.root.get_node_or_null("Main_Scene")
	if world == null:
		# try current scene before forcing a change
		var current := tree.current_scene
		if current and current.name == "Main_Scene":
			world = current

	if world == null:
		# load the main scene so multiplayer can spawn players
		var err := tree.change_scene_to_file(WORLD_SCENE_PATH)
		if err != OK:
			push_error("Could not change to main scene: %s" % err)
			return tree.root
		world = tree.current_scene

	return world


func _setup_spawner(world: Node) -> MultiplayerSpawner:
	if world == null:
		return null

	var spawner: MultiplayerSpawner = world.get_node_or_null(SPAWNER_PATH)
	return _configure_spawner(spawner)


func _configure_spawner(spawner: MultiplayerSpawner) -> MultiplayerSpawner:
	if spawner == null:
		push_error("No MultiplayerSpawner found in world; cannot spawn players.")
		return null

	# set once; this runs on all peers so spawn_function exists when replication kicks in
	if spawner.spawn_function.is_null():
		spawner.spawn_function = Callable(self, "_spawn_custom_player")

	return spawner


func _spawn_custom_player(data) -> Node:
	var payload: Dictionary = {}
	if data is Dictionary:
		payload = data
	else:
		payload["player_id"] = data
	var id := int(payload.get("player_id", 0))
	var player := PLAYER_SCENE.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	return player


func _spawn_player(id: int) -> void:
	var world := _get_world()
	if world == null:
		return

	var spawner := _setup_spawner(world)
	if spawner == null:
		return

	if world.get_node_or_null(str(id)):
		return

	# this runs only on the server; spawner will replicate to clients
	spawner.spawn({"player_id": id})
	_spawned_player_ids.append(id)
	print("Spawned player", id, "via MultiplayerSpawner")


func _teardown_session() -> void:
	# Cleanly close any existing session so we can rehost or reconnect
	if multiplayer.has_multiplayer_peer():
		peer.close()
		multiplayer.multiplayer_peer = null

	# Remove any previously spawned player nodes
	var world := get_tree().root.get_node_or_null("Main_Scene")
	if world:
		for player_id in _spawned_player_ids:
			var node := world.get_node_or_null(str(player_id))
			if node:
				node.queue_free()

	_spawned_player_ids.clear()
	peer = ENetMultiplayerPeer.new()


func _on_node_added(node: Node) -> void:
	# If the spawner is added after scene change, make sure it has the spawn function set.
	if node is MultiplayerSpawner and node.name == SPAWNER_PATH:
		_configure_spawner(node)
