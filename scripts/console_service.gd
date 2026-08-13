class_name ConsoleService
extends Node

var console_manager: Node

var _server: TCPServer = TCPServer.new()
var _clients: Array[ConsoleServiceClient] = []


func _init(manager: Node) -> void:
	console_manager = manager
	name = "GTermWebsocketService"


func start_service(service_port: int = 3939) -> void:
	var err: int = _server.listen(service_port)

	if err != OK:
		push_warning("GTERM WebSocket service failed to listen on port %d" % service_port)
		return

	print("GTERM WebSocket service listening on ws://localhost:%d" % service_port)


func _process(_delta: float) -> void:
	_accept_connections()
	_process_clients()


func _accept_connections() -> void:
	while _server.is_connection_available():
		var tcp_peer: StreamPeerTCP = _server.take_connection()

		if tcp_peer == null:
			continue

		tcp_peer.set_no_delay(true)

		var websocket := WebSocketPeer.new()

		var err := websocket.accept_stream(tcp_peer)

		if err != OK:
			push_warning("GTERM failed to upgrade connection to WebSocket: %s" % error_string(err))
			continue

		var client := ConsoleServiceClient.new(websocket)

		client.console_manager = console_manager

		add_child(client)

		_clients.append(client)


func _process_clients() -> void:
	for client: ConsoleServiceClient in _clients.duplicate():
		var peer := client.get_peer()

		peer.poll()

		match peer.get_ready_state():
			WebSocketPeer.STATE_CONNECTING:
				# WebSocket HTTP upgrade is still being processed.
				pass

			WebSocketPeer.STATE_OPEN:
				if not client.is_initialized():
					_initialize_client(client)

				_process_client_input(client)

			WebSocketPeer.STATE_CLOSING:
				# Keep polling until STATE_CLOSED.
				pass

			WebSocketPeer.STATE_CLOSED:
				_remove_client(client)


func _initialize_client(client: ConsoleServiceClient) -> void:
	client.mark_initialized()


func _process_client_input(client: ConsoleServiceClient) -> void:
	var peer := client.get_peer()

	while peer.get_available_packet_count() > 0:
		var packet := peer.get_packet()

		if not peer.was_string_packet():
			continue

		var input := packet.get_string_from_utf8().strip_edges()

		if input.is_empty():
			continue

		if input == "quit" or input == "exit":
			client.print_remote("Bye bye!\n")

			peer.close(1000, "Client disconnected")

			continue

		client.run_from_remote(input)


func _remove_client(client: ConsoleServiceClient) -> void:
	_clients.erase(client)

	if is_instance_valid(client):
		client.queue_free()


func _exit_tree() -> void:
	for client: ConsoleServiceClient in _clients.duplicate():
		var peer := client.get_peer()

		if peer != null and peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
			peer.close(1001, "Server shutting down")

		client.queue_free()

	_clients.clear()

	_server.stop()
