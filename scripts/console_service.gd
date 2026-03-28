class_name ConsoleService
extends Node

const SERVICE_PORT: int = 3939
var _server: TCPServer = TCPServer.new()
var _clients: Array[ConsoleServiceClient]


func start_service() -> void:
	var err: int = _server.listen(SERVICE_PORT)
	if err != OK:
		push_warning("Could not listen on port %s" % SERVICE_PORT)
		return
		
	print("Telnet server listening on port %s!" % SERVICE_PORT)

func _process(_delta):
	# Accept new clients
	if _server.is_connection_available():
		var peer := _server.take_connection()
		peer.set_no_delay(true)

		var client: ConsoleServiceClient = ConsoleServiceClient.new(peer)
		add_child(client)

		_clients.append(client)

		for line in Console.get_banner().replace("\r\n", "\n").split("\n", false):
			client.print_remote(line + "\r\n")

		client.print_remote("Use the /help command to print the available commands\r\n")
		client.print_remote("\r\n")
		client.print_remote("> ")

	# Handle client input
	for client in _clients.duplicate():
		if client.get_peer().get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_clients.erase(client)
			client.queue_free()
			continue

		if client.get_peer().get_available_bytes() > 0:
			var input: String = (
				client.get_peer().get_string(client.get_peer().get_available_bytes()).strip_edges()
			)
			# Handle quit here
			if input == "quit" or input == "exit":
				client.print_remote("Bye bye! miauu\r\n")
				client.get_peer().disconnect_from_host()
				_clients.erase(client)
				client.queue_free()
				continue

			client.run_from_remote(input)
