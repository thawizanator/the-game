extends Control

# Core Nodes UI references
@onready var room_key_input: LineEdit = $VBoxContainer/RoomControlSection/MarginContainer/VBox/HBox/RoomKeyInput
@onready var verify_key_btn: Button = $VBoxContainer/RoomControlSection/MarginContainer/VBox/HBox/VerifyKeyBtn
@onready var status_text_label: Label = $VBoxContainer/RoomControlSection/MarginContainer/VBox/StatusTextLabel
@onready var join_room_btn: Button = $VBoxContainer/JoinRoomBtn
# @onready var discord_btn: Button = $VBoxContainer/CommunitySection/DiscordBtn
@onready var exit_btn: Button = $ExitBtn

# Network Reference (Uses the global SocketIO node or direct fallback)
var socket_io = null
var is_socket_connected: bool = false

# System state variables
var verified_room_code: String = ""
var verified_username: String = "Anonymous Player"

func _ready() -> void:
	print("🎮 Player Title Screen Booting Up...")
	
	# Initial UI state configuration
	join_room_btn.disabled = true
	status_text_label.text = "Enter a room key code to verify connection."
	status_text_label.add_theme_color_override("font_color", Color.YELLOW)
	
	# Wire up button connections cleanly via code
	verify_key_btn.pressed.connect(_on_verify_key_pressed)
	join_room_btn.pressed.connect(_on_join_room_pressed)
	# discord_btn.pressed.connect(_on_discord_btn_pressed)
	exit_btn.pressed.connect(_on_exit_btn_pressed)
	
	# Connect to standard Socket.io network node
	_initialize_network_socket()


# --- SOCKET NETWORK & ROOM VALIDATION ---

func _initialize_network_socket() -> void:
	# Try to find SocketIO instance in running scene root tree
	if has_node("/root/SocketIO"):
		socket_io = get_node("/root/SocketIO")
	elif has_node("SocketIO"):
		socket_io = get_node("SocketIO")
	elif has_node("SocketIOClient"):
		socket_io = get_node("SocketIOClient")
		
	if socket_io != null:
		print("📡 Connected player client directly to Socket node wrapper!")
		# Listen to incoming response from Node server
		if socket_io.has_signal("event_received"):
			socket_io.connect("event_received", _on_socket_event)
	else:
		print("⚠️ Player Title Screen cannot find Socket.io node. Check your main tree!")

func _on_verify_key_pressed() -> void:
	var entered_code = room_key_input.text.strip_edges().to_upper()
	if entered_code == "":
		status_text_label.text = "❌ Error: Please input a room key first!"
		status_text_label.add_theme_color_override("font_color", Color.RED)
		return
		
	status_text_label.text = "Searching TV Switchboard for '" + entered_code + "'..."
	status_text_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	
	if socket_io != null:
		# Send structured verification request packet up to server
		var payload = JSON.stringify({
			"roomCode": entered_code
		})
		
		# Call standard emit sequence
		if socket_io.has_method("emit"):
			socket_io.emit("verify_room_key", payload)
		elif "socket" in socket_io:
			socket_io.socket.emit("verify_room_key", payload)
	else:
		# Network offline simulation fallback (Let them test room: 'STUDIO8')
		await get_tree().create_timer(1.0).timeout
		if entered_code == "STUDIO8" or entered_code == "ADMIN":
			_on_room_verified_success(entered_code)
		else:
			status_text_label.text = "❌ Room code not found in offline mock simulation."
			status_text_label.add_theme_color_override("font_color", Color.RED)

func _on_socket_event(event_name: String, data: Variant, _namespace: Variant = null) -> void:
	print("📡 Player Title incoming network packet -> '", event_name, "'")
	
	# Unpack dynamic payload arrays / strings securely
	var parsed_data = data
	if typeof(data) == TYPE_ARRAY and data.size() > 0:
		parsed_data = data[0]
	if typeof(parsed_data) == TYPE_STRING:
		parsed_data = JSON.parse_string(parsed_data)
		
	if event_name == "room_verification_response" and typeof(parsed_data) == TYPE_DICTIONARY:
		var exists = parsed_data.get("exists", false)
		var code = parsed_data.get("roomCode", "")
		
		if exists:
			_on_room_verified_success(code)
		else:
			status_text_label.text = "❌ Error: Room Key '" + code + "' is inactive or closed!"
			status_text_label.add_theme_color_override("font_color", Color.RED)
			join_room_btn.disabled = true

func _on_room_verified_success(code: String) -> void:
	verified_room_code = code
	status_text_label.text = "✅ Room Active! Welcome to Live Broadcast Stage."
	status_text_label.add_theme_color_override("font_color", Color.GREEN)
	join_room_btn.disabled = false
	join_room_btn.text = "🚀 JOIN LOBBY MATCH (" + verified_room_code + ")"

func _on_join_room_pressed() -> void:
	print("🚀 Joining game show match... Redirecting to Player Interface!")
	
	if socket_io != null:
		var payload = JSON.stringify({
			"username": verified_username,
			"roomCode": verified_room_code,
			"isTwitchUser": false
		})
		socket_io.emit("join_game", payload)
		
	# Transition into the actual interactive game dashboard screen
	get_tree().change_scene_to_file("res://main_studio.tscn")


# --- NAVIGATION & UI BUTTON ACTIONS ---

func _on_discord_btn_pressed() -> void:
	print("💬 Redirecting player to Discord Server community...")
	OS.shell_open("https://discord.gg/invite_link_here")

func _on_exit_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://title_screen.tscn")
	
func _input(event):
	# Global Nuclear Option Kill Switch Shortcut
	if Input.is_key_pressed(KEY_KP_5) and Input.is_key_pressed(KEY_SHIFT):
		print("☢️ EMERGENCY FAIL-SAFE TRIPPED! Closing environment down...")
		get_tree().quit()
