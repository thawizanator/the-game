extends CanvasLayer

@onready var socket_io = $SocketIO

# Core Dashboard Layout Containers
@onready var main_dashboard = $MainDashboard
@onready var left_control_panel = $MainDashboard/LeftControlPanel
@onready var right_broadcast_display = $MainDashboard/RightBroadcastDisplay

# Game & Broadcast UI Elements (Nested inside the 16:9 Right Display)
@onready var active_view_content = $MainDashboard/RightBroadcastDisplay/BroadcastViewportFrame/ActiveViewContent
@onready var board_grid = $MainDashboard/RightBroadcastDisplay/BroadcastViewportFrame/ActiveViewContent/BoardGrid
@onready var voting_panel = $MainDashboard/RightBroadcastDisplay/BroadcastViewportFrame/ActiveViewContent/VotingPanel
@onready var lobby_panel = $MainDashboard/RightBroadcastDisplay/BroadcastViewportFrame/ActiveViewContent/LobbyPanel

# Nested Elements inside VotingPanel
@onready var cats_vote_bar = $MainDashboard/RightBroadcastDisplay/BroadcastViewportFrame/ActiveViewContent/VotingPanel/BarChartContainer/CatsVoteBar
@onready var sharks_vote_bar = $MainDashboard/RightBroadcastDisplay/BroadcastViewportFrame/ActiveViewContent/VotingPanel/BarChartContainer/SharksVoteBar

# Nested Elements inside LobbyPanel
@onready var audience_counter = $MainDashboard/RightBroadcastDisplay/BroadcastViewportFrame/ActiveViewContent/LobbyPanel/AudienceCounter
@onready var roll_call_list = $MainDashboard/RightBroadcastDisplay/BroadcastViewportFrame/ActiveViewContent/LobbyPanel/RollCallList

# ==================== NEW REFERENCE DECLARATIONS ====================
# Toolbar Control Buttons (Nested inside the Left Panel Control Tabs)
@onready var lobby_view_btn = $MainDashboard/LeftControlPanel/ControlTabs/Games/LobbyViewBtn
@onready var poll_view_btn = $MainDashboard/LeftControlPanel/ControlTabs/Games/PollViewBtn
@onready var bidding_view_btn = $MainDashboard/LeftControlPanel/ControlTabs/Games/BiddingViewBtn

# Phase 4 Micro-Game: Bidding War Interface References
@onready var bidding_panel = $MainDashboard/LeftControlPanel/ControlTabs/Games/BiddingPanel
@onready var question_input = $MainDashboard/LeftControlPanel/ControlTabs/Games/BiddingPanel/QuestionInput
@onready var answer_input = $MainDashboard/LeftControlPanel/ControlTabs/Games/BiddingPanel/AnswerInput
@onready var launch_bid_btn = $MainDashboard/LeftControlPanel/ControlTabs/Games/BiddingPanel/LaunchBidBtn
@onready var winner_announcement = $MainDashboard/LeftControlPanel/ControlTabs/Games/BiddingPanel/WinnerAnnouncement

# Admin Control Panel Elements (Nested inside the Left Tab Container)
@onready var admin_user_list = $MainDashboard/LeftControlPanel/ControlTabs/Administration/ModScroll/AdminUserList
# ====================================================================

var selected_tile_index: int = -1
var is_connected_to_server: bool = false 

# Array to track connected players and prevent duplicate lobby entries
var connected_players: Array = []

func _ready():
	print("📺 Studio Screen Initializing...")
	randomize()
	
	# 1. Establish initial display state (Show grid/lobby, hide voting bars)
	if audience_counter:
		audience_counter.text = "LIVE AUDIENCE: 0"
	_show_lobby_state()
	
	# 2. Wire up our control toolbar clicks programmatically
	if lobby_view_btn:
		lobby_view_btn.pressed.connect(_on_lobby_view_pressed)
	if poll_view_btn:
		poll_view_btn.pressed.connect(_on_poll_view_pressed)
		
	# Hide the setup block layout initially on boot
	if bidding_panel: bidding_panel.visible = false
	
	# Map the extra toolbar button toggle and emission push signal
	if bidding_view_btn:
		bidding_view_btn.pressed.connect(_on_bidding_view_pressed)
	if launch_bid_btn:
		launch_bid_btn.pressed.connect(_on_launch_bid_btn_pressed)
	
	# 3. Connect the core event packet listener
	socket_io.event_received.connect(_on_socket_event_received)
	
	# 4. FORCE INDEPENDENT HANDSHAKE
	print("🔌 Forcing manual handshake request to Node server...")
	if socket_io.has_method("connect_socket"):
		socket_io.connect_socket()
	elif socket_io.has_method("connect_to_server"):
		socket_io.connect_to_server()
	
	# 5. Dynamic layout setup for the 9 grid boxes
	var tiles = board_grid.get_children()
	for i in range(tiles.size()):
		tiles[i].pressed.connect(_on_tile_clicked.bind(i))
		tiles[i].text = "Tile " + str(i + 1)
		tiles[i].custom_minimum_size = Vector2(150, 150)

# TOOLBAR BUTTON INTERACTION 1: Switch back to main board view
func _on_lobby_view_pressed():
	print("🎛️ Toolbar clicked: Switching to Main Game Board view.")
	_show_lobby_state()

# TOOLBAR BUTTON INTERACTION 2: Open and fire the live selection ballot poll
func _on_poll_view_pressed():
	if not is_connected_to_server:
		print("⚠️ Cannot trigger vote! Server state is currently: DISCONNECTED.")
		return
		
	print("🎛️ Toolbar clicked: Triggering Live Audience Mini-Game Vote!")
	_show_voting_state()
	
	# Tell the Node.js server to transform player controller screens instantly!
	socket_io.emit("host_trigger_lobby_poll", {})

# Helper state utility to toggle panel combinations cleanly
func _show_lobby_state():
	if board_grid: board_grid.visible = true
	if lobby_panel: lobby_panel.visible = true
	if voting_panel: voting_panel.visible = false
	if bidding_panel: bidding_panel.visible = false

func _show_voting_state():
	if board_grid: board_grid.visible = false
	if lobby_panel: lobby_panel.visible = false
	if voting_panel: voting_panel.visible = true
	if bidding_panel: bidding_panel.visible = false

# Triggers when the Streamer clicks a grid tile box on screen
func _on_tile_clicked(index: int):
	if not is_connected_to_server:
		print("⚠️ CANNOT CLICK TILE! Engine network state is still: DISCONNECTED.")
		return
		
	selected_tile_index = index
	print("Host selected Tile: ", index + 1)
	
	var raw_data = {
		"tileIndex": index,
		"correctAnswer": "B"
	}
	
	var json_string = JSON.stringify(raw_data)
	socket_io.emit("host_start_question", [ json_string ])
	board_grid.get_child(index).modulate = Color(1, 1, 0)

# Listen to incoming Node.js game packets
func _on_socket_event_received(event_name: String, data: Variant, _namespace = null):
	print("📡 NETWORK INCOMING -> Event: '", event_name, "' | Data: ", data)

	if not is_connected_to_server:
		is_connected_to_server = true

	if event_name == "connect" or event_name == "connected":
		is_connected_to_server = true
		return
	elif event_name == "disconnect":
		is_connected_to_server = false
		return

	match event_name:
		"assign_team":
			_handle_player_joined(data)
		"lobby_poll_update":
			_update_live_ballot_bars(data)
		"live_vote_update":
			print("Current Tally: ", data)
		"grid_tile_resolved":
			_resolve_tile(data)
		"bidding_leader_update":
			_handle_leader_board_flash(data)

# Phase 2: Process a player entering the studio lobby
func _handle_player_joined(data: Variant):
	var parsed_data = data
	if typeof(data) == TYPE_ARRAY and data.size() > 0:
		parsed_data = data[0]
	if typeof(parsed_data) == TYPE_STRING:
		parsed_data = JSON.parse_string(parsed_data)
		
	if parsed_data == null or typeof(parsed_data) != TYPE_DICTIONARY:
		return
		
	var username = parsed_data.get("username", "").strip_edges()
	if username == "":
		username = "Viewer_" + str(randi() % 1000) + "_" + str(Time.get_ticks_msec() % 1000)
	
	var team = parsed_data.get("team", "cats")
	
	if username == "Host" or connected_players.has(username):
		return
		
	connected_players.append(username)
	
	if audience_counter:
		audience_counter.text = "LIVE AUDIENCE: " + str(connected_players.size())
		
	if roll_call_list:
		var new_player_label = Label.new()
		var team_marker = "[CATS]" if team == "cats" else "[SHARKS]"
		new_player_label.text = team_marker + " " + username
		
		if team == "cats":
			new_player_label.modulate = Color(1.0, 0.0, 0.5)
		else:
			new_player_label.modulate = Color(0.0, 0.94, 1.0)
			
		roll_call_list.add_child(new_player_label)

# Phase 3: Reads live game poll changes from server and scales progress bars
func _update_live_ballot_bars(data: Variant):
	var parsed_data = data
	if typeof(data) == TYPE_ARRAY and data.size() > 0:
		parsed_data = data[0]
	if typeof(parsed_data) == TYPE_STRING:
		parsed_data = JSON.parse_string(parsed_data)

	if parsed_data == null or typeof(parsed_data) != TYPE_DICTIONARY:
		return

	var cat_votes = float(parsed_data.get("cats", 0))
	var shark_votes = float(parsed_data.get("sharks", 0))
	var total_votes = cat_votes + shark_votes

	if total_votes > 0:
		cats_vote_bar.value = (cat_votes / total_votes) * 100
		sharks_vote_bar.value = (shark_votes / total_votes) * 100
	else:
		cats_vote_bar.value = 0
		sharks_vote_bar.value = 0

func _resolve_tile(data: Dictionary):
	var index = int(data.get("tileIndex", -1))
	var winner = data.get("winner", "tie")
	var tile_button = board_grid.get_child(index) as Button
	
	if winner == "cats":
		tile_button.modulate = Color(1, 0, 0.5)
		tile_button.text = "CATS\n" + str(data.get("catAcc")) + "%"
	elif winner == "sharks":
		tile_button.modulate = Color(0, 0.94, 1)
		tile_button.text = "SHARKS\n" + str(data.get("sharkAcc")) + "%"
	else:
		tile_button.modulate = Color(0.5, 0.5, 0.5)
		tile_button.text = "TIE"

# Phase 4
func _on_bidding_view_pressed():
	print("🎛️ Toolbar clicked: Opening Bidding War setup panels.")
	if board_grid: board_grid.visible = false
	if lobby_panel: lobby_panel.visible = false
	if voting_panel: voting_panel.visible = false
	if bidding_panel: bidding_panel.visible = true

func _on_launch_bid_btn_pressed():
	if not is_connected_to_server: return
	
	var question = question_input.text.strip_edges()
	var answer = answer_input.text.strip_edges()
	
	if question == "" or answer == "":
		print("⚠️ Cannot launch! Inputs cannot be blank.")
		return
		
	var payload = {
		"questionText": question,
		"targetAnswer": answer
	}
	
	if winner_announcement: winner_announcement.text = "GATHERING AUDIENCE SUBMISSIONS..."
	
	# Fire the data package safely up to your Node server!
	socket_io.emit("host_launch_bidding", [ JSON.stringify(payload) ])

func _handle_leader_board_flash(data: Variant):
	var parsed_data = data
	if typeof(data) == TYPE_ARRAY and data.size() > 0: parsed_data = data[0]
	if typeof(parsed_data) == TYPE_STRING: parsed_data = JSON.parse_string(parsed_data)
	
	if parsed_data == null or typeof(parsed_data) != TYPE_DICTIONARY: return
	
	var leader = parsed_data.get("leaderName", "No valid bids yet")
	var guess = parsed_data.get("leaderGuess", 0)
	var total = parsed_data.get("totalBids", 0)
	
	if winner_announcement:
		winner_announcement.text = "CURRENT LEADER: " + leader + " with a bid of " + str(guess) + " (Total Bids: " + str(total) + ")"

# ==================== GLOBAL UNIFIED INPUT HANDLING ====================
func _input(event):
	# 1. The Nuclear Option / Fail-Safe Kill Combination 
	if Input.is_key_pressed(KEY_KP_5) and Input.is_key_pressed(KEY_SHIFT):
		print("☢️ EMERGENCY FAIL-SAFE TRIPPED! Closing environment down...")
		get_tree().quit()
		
