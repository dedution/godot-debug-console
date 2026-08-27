class_name ConsoleWebClient
extends Node

## CLI web interface to interact with gterm. Connects to the websockets service

var console_manager: Node
var _server: TCPServer = TCPServer.new()
var _http_clients: Array[Dictionary] = []
var _interface_file: String = "/web/gterm_cli.html"
var _font_file: String = "/fonts/RobotoMono-Regular.ttf"
var _body_data: String = "<h1>Failed to load content. Contact admin nooby cola.</h1>"
var _font_data: PackedByteArray = PackedByteArray()


func _init(manager: Node):
	console_manager = manager
	self.name = "GTermWebInterface"
	console_manager.add_child(self)

	var root_folder: String = get_script().resource_path.get_base_dir().get_base_dir()
	_body_data = _get_text_file_content(root_folder + _interface_file)
	_font_data = _get_binary_file_content(root_folder + _font_file)


func _get_text_file_content(file_path: String) -> String:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("GTERM failed to load web interface: %s" % file_path)
		return _body_data
	return file.get_as_text()


func _get_binary_file_content(file_path: String) -> PackedByteArray:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("GTERM failed to load web font: %s" % file_path)
		return PackedByteArray()
	return file.get_buffer(file.get_length())


func update_page_data(websocket_port: int) -> void:
	var machine_ip := Commands.get_local_ip()
	var banner: String = console_manager.get_banner() if console_manager else "Welcome to GTerm!"
	banner = banner.replace("\r\n", "\n").trim_suffix("\n")
	banner = _banner_to_html(banner)

	_body_data = _body_data.replace("___BANNER_SECTION___", banner)
	_body_data = _body_data.replace("___MACHINE_IP___", machine_ip)
	_body_data = _body_data.replace("___WEBSOCKET_PORT___", str(websocket_port))
	_body_data = _body_data.replace("___FONT_DATA___", Marshalls.raw_to_base64(_font_data))


func _escape_html(value: String) -> String:
	return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


func _banner_to_html(value: String) -> String:
	var result := ""
	var character_count := max(value.length(), 1)
	var index := 0

	for character in value:
		var hue := int(float(index) / character_count * 360.0)
		result += (
			'<span class="banner-char" style="--banner-hue:%d">%s</span>'
			% [hue, _escape_html(character)]
		)
		index += 1

	return result


func start_service(service_port: int = 8080, websocket_port: int = 3939) -> void:
	update_page_data(websocket_port)

	var error := _server.listen(service_port)

	if error != OK:
		push_error("Failed to start GTERM web interface on port %d" % service_port)
		return

	print("GTERM web interface started on port %s!" % service_port)


func _process(_delta: float) -> void:
	_accept_http_connections()
	_process_http_clients()


func _accept_http_connections() -> void:
	while _server.is_connection_available():
		var client := _server.take_connection()
		if client == null:
			continue
		client.set_no_delay(true)
		(
			_http_clients
			. append(
				{
					"peer": client,
					"request": "",
					"responded": false,
					"close_ticks": 0,
				}
			)
		)


func _process_http_clients() -> void:
	for entry: Dictionary in _http_clients.duplicate():
		var client: StreamPeerTCP = entry["peer"]
		client.poll()

		if (
			client.get_status() == StreamPeerTCP.STATUS_NONE
			or client.get_status() == StreamPeerTCP.STATUS_ERROR
		):
			_http_clients.erase(entry)
			continue

		if entry["responded"]:
			entry["close_ticks"] += 1
			if entry["close_ticks"] < 2:
				continue
			client.disconnect_from_host()
			_http_clients.erase(entry)
			continue

		if client.get_available_bytes() <= 0:
			continue

		entry["request"] += client.get_string(client.get_available_bytes())
		if not entry["request"].contains("\r\n\r\n"):
			continue

		var request_line: String = entry["request"].get_slice("\n", 0).strip_edges()
		var request_parts := request_line.split(" ")
		var request_path := "/"
		if request_parts.size() >= 2:
			request_path = request_parts[1].get_slice("?", 0)

		if request_path == "/gterm-font.ttf":
			_send_response(client, "font/ttf", _font_data)
		else:
			_send_response(client, "text/html; charset=utf-8", _body_data.to_utf8_buffer())

		entry["responded"] = true


func _send_response(client: StreamPeerTCP, content_type: String, body: PackedByteArray) -> void:
	var headers := (
		"HTTP/1.1 200 OK\r\n"
		+ "Content-Type: %s\r\n" % content_type
		+ "Content-Length: %d\r\n" % body.size()
		+ "Cache-Control: no-cache\r\n"
		+ "Connection: close\r\n"
		+ "\r\n"
	)
	client.put_data(headers.to_utf8_buffer())
	client.put_data(body)


func _exit_tree() -> void:
	for entry: Dictionary in _http_clients:
		var client: StreamPeerTCP = entry["peer"]
		client.disconnect_from_host()
	_http_clients.clear()
	_server.stop()
