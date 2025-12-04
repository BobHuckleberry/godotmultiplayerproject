extends Node   # Autoload

const PORT := 4242
const MAX_CLIENTS := 8
const WORLD_SCENE_PATH := "res://Scenes/main_scene.tscn"

# Use Copy Path on your player scene in the FileSystem and paste here:
const PLAYER_SCENE: PackedScene = preload("res://Scenes/Player.tscn")

var peer := ENetMultiplayerPeer.new()


# ----------------- BUTTON ENTRY POINTS -----------------

func create_server() -> void:
	print("Creating server...")
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		push_error("Failed to create server: %s" % err)
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)

	# spawn host player
	_spawn_player(multiplayer.get_unique_id())


func join_server(host: String) -> void:
	print("Joining server at:", host)
	var err := peer.create_client(host, PORT)
	if err != OK:
		push_error("Failed to connect: %s" % err)
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)


# ----------------- SIGNAL CALLBACK -----------------

func _on_peer_connected(id: int) -> void:
	print("Peer connected:", id)
	_spawn_player(id)


# ----------------- WORLD + SPAWN HELPERS -----------------

func _get_world() -> Node:
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


func _spawn_player(id: int) -> void:
	var world := _get_world()
	if world == null:
		return

	# If you later add a Players node, use it here:
	var players := world.get_node_or_null("Players")
	if players == null:
		players = world

	var player := PLAYER_SCENE.instantiate()
	player.name = str(id)

	players.add_child(player)
	print("Spawned player", id, "under", players.name)
