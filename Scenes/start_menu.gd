extends Control

@onready var address_field: LineEdit = $VBoxContainer/AddressLineEdit  # if you have one

func _on_server_pressed() -> void:
	NetworkHandler.create_server()

func _on_client_pressed() -> void:
	# If you don’t have a LineEdit yet, hard-code "127.0.0.1" for local testing
	var host := address_field.text if is_instance_valid(address_field) else "127.0.0.1"
	if !host:
		host = "127.0.0.1"
	
	NetworkHandler.join_server(host)
