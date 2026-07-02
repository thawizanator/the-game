extends Control

# UI Container references
@onready var main_menu_container: VBoxContainer = $MainMenuContainer
@onready var main_menu_background: TextureRect = $Background
@onready var host_menu_container: PanelContainer = $HostContainer
@onready var studio_setup_container: ScrollContainer = $StudioSetupContainer

# Studio Setup Node Input Mappings
@onready var player_count_spin: SpinBox = $StudioSetupContainer/VBox/PlayersRow/PlayerCountSpin
@onready var mod_count_spin: SpinBox = $StudioSetupContainer/VBox/ModsRow/ModCountSpin
@onready var dual_monitor_check: CheckBox = $StudioSetupContainer/VBox/MonitorRow/DualMonitorCheck
@onready var separate_windows_check: CheckBox = $StudioSetupContainer/VBox/MonitorRow/SeparateWindowsCheck
@onready var score_mode_option: OptionButton = $StudioSetupContainer/VBox/ScoreRow/ScoreModeOption
@onready var twitch_interact_check: CheckBox = $StudioSetupContainer/VBox/TwitchRow/TwitchInteractCheck

# Active Games Grid Checks
@onready var game_1_check: CheckBox = $StudioSetupContainer/VBox/GamesGrid/Game1Check
@onready var game_2_check: CheckBox = $StudioSetupContainer/VBox/GamesGrid/Game2Check
@onready var game_3_check: CheckBox = $StudioSetupContainer/VBox/GamesGrid/Game3Check
@onready var game_4_check: CheckBox = $StudioSetupContainer/VBox/GamesGrid/Game4Check

# One config file for everything
const SAVE_PATH = "user://studio_settings.cfg"

# Twitch Panel
@onready var twitch_status_label: Label = $TwitchPanelContainer/tsVboxTwitch/TwitchStatusLabel
@onready var twitch_info_label: Label = $TwitchPanelContainer/tsVboxTwitch/twitch_info
@onready var twitch_connect_btn: Button = $TwitchPanelContainer/tsVboxTwitch/TwitchConnectBtn

# TESTING CRAP
var twitch_addon = null

func _ready() -> void:
	print("🎬 Title Screen Room Initialized...")
	
	# Dynamic lookup to catch the plugin's background manager reference
	if get_node_or_null("/root/TwitchService") != null:
		twitch_addon = get_node("/root/TwitchService")
	elif get_node_or_null("/root/Twitcher") != null:
		twitch_addon = get_node("/root/Twitcher")

	# Check authorization states right away on startup!
	if check_existing_twitch_authorization():
		# Update UI components to a safe "Connected" status layout
		twitch_info_label.text = "Twitch Status: Active ✅"
		twitch_connect_btn.text = "🔐 Unlink Account"
	else:
		# Keep interface elements on default unlinked baseline parameters
		twitch_info_label.text = "Twitch Status: Unlinked 🔗"
		twitch_connect_btn.text = "🔐 Connect Twitch Account"
	
	#What containers are visible at start
	main_menu_container.visible = true
	main_menu_background.visible = true
	host_menu_container.visible = false
	studio_setup_container.visible = false
	
	# Populate our Scoreboard Option dropdown
	score_mode_option.clear()
	score_mode_option.add_item("Per Session", 0)
	score_mode_option.add_item("Keep Running Total", 1)
	
	# Automatically look for and load previous configurations
	load_studio_settings()

	# Connect the twitch button click via code safely
	if twitch_connect_btn:
		if not twitch_connect_btn.pressed.is_connected(_on_twitch_connect_btn_pressed):
			twitch_connect_btn.pressed.connect(_on_twitch_connect_btn_pressed)

	# Execute our sequential Twitch system health checks
	check_twitch_reachability()
	check_twitch_authorization()


# --- TWITCH INTEGRATION LOGIC ---

func check_twitch_authorization() -> void:
	# 1. Grab the running background instance of Twitcher
	if Engine.has_singleton("TwitchService"):
		twitch_addon = Engine.get_singleton("TwitchService")
	elif get_node_or_null("/root/TwitchService") != null:
		twitch_addon = get_node("/root/TwitchService")
	elif get_node_or_null("/root/Twitcher") != null:
		twitch_addon = get_node("/root/Twitcher")
		
	if twitch_addon == null:
		print("ℹ️ Twitcher plugin manager instance is not active.")
		twitch_info_label.text = "Twitch Status: Addon Missing ❌"
		return

	print("🔍 Querying Twitcher API for active login authorization tokens...")
	
	# 2. Safely check across V2 structures if an authorized token exists
	var is_authorized: bool = false
	if twitch_addon.has_method("is_authenticated"):
		is_authorized = twitch_addon.is_authenticated()
	elif "is_authenticated" in twitch_addon:
		is_authorized = twitch_addon.is_authenticated
		
	# 3. Update the menu UI layout elements dynamically
	if is_authorized:
		var streamer_name = "Streamer"
		if "username" in twitch_addon:
			streamer_name = twitch_addon.username
		elif twitch_addon.has_method("get_username"):
			streamer_name = twitch_addon.get_username()
			
		print("✅ Cached account token validated for user: ", streamer_name)
		twitch_info_label.text = "Twitch Status: Connected as " + str(streamer_name) + " ✅"
		#twitch_status_label.add_theme_color_override("font_color", Color.GREEN)
		twitch_connect_btn.text = "🔐 Disconnect Account"
	else:
		print("🔗 No valid account token found. Ready for initial login handshake.")
		#twitch_info_label.text = "Twitch Status: Unlinked 🔗"
		#twitch_status_label.add_theme_color_override("font_color", Color.WHITE)
		twitch_connect_btn.text = "🔐 Connect Twitch Account"

func _on_twitch_connect_btn_pressed() -> void:
	print("🎯 Connect button pressed successfully!") # <-- Check if this prints!
	
	if twitch_addon == null:
		print("⚠️ Cannot authenticate. Twitcher manager instance is null.")
		return
		
	var is_logged_in: bool = false
	if twitch_addon.has_method("is_authenticated"):
		is_logged_in = twitch_addon.is_authenticated()
	elif "is_authenticated" in twitch_addon:
		is_logged_in = twitch_addon.is_authenticated

	if not is_logged_in:
		print("🔐 Initiating Twitch OAuth browser authorization...")
		twitch_info_label.text = "Status: Opening Web Browser..."
		#twitch_status_label.add_theme_color_override("font_color", Color.CYAN)
		
		# Hook up signals
		if twitch_addon.has_signal("login_completed") and not twitch_addon.login_completed.is_connected(check_twitch_authorization):
			twitch_addon.login_completed.connect(check_twitch_authorization)
		elif twitch_addon.has_signal("auth_complete") and not twitch_addon.auth_complete.is_connected(check_twitch_authorization):
			twitch_addon.auth_complete.connect(check_twitch_authorization)
			
		print("🚀 Calling plugin login method...") # <-- Check if this prints!
		
		# Open system browser context
		if twitch_addon.has_method("login"):
			twitch_addon.login()
		elif twitch_addon.has_method("setup"):
			twitch_addon.setup()
		else:
			print("❌ Error: Could not find a 'login' or 'setup' method on the addon!")
	else:
		print("🔓 Disconnecting account...")
		if twitch_addon.has_method("logout"):
			twitch_addon.logout()
		elif twitch_addon.has_method("disconnect_service"):
			twitch_addon.disconnect_service()
		check_twitch_authorization()


func check_twitch_reachability() -> void:
	print("🌐 Testing basic reachability to Twitch API servers...")
	var http_client = HTTPRequest.new()
	add_child(http_client)
	
	http_client.request_completed.connect(
		func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
			_on_reachability_response(result, response_code, http_client)
	)
	
	var url = "https://api.twitch.tv"
	var error = http_client.request(url, PackedStringArray(), HTTPClient.METHOD_GET)
	
	if error != OK:
		print("❌ Failed to initiate reachability request. Local network issue.")
		# twitch_reachability_label.text = "Twitch API: Local Error 🔌"
		# twitch_reachability_label.add_theme_color_override("font_color", Color.RED)
		GlobalSystem.save_custom_setting("Twitch Reachability","false")
		http_client.queue_free()
	else:
		GlobalSystem.save_custom_setting("Twitch Reachability","true")
			
func _on_reachability_response(result: int, response_code: int, worker_node: HTTPRequest) -> void:
	worker_node.queue_free()
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code > 0:
		print("🟢 Twitch Services are fully responsive! Response Code: ", response_code)
		# twitch_reachability_label.text = "Twitch API: Reachable ✅"
		# twitch_reachability_label.add_theme_color_override("font_color", Color.GREEN)
		GlobalSystem.save_custom_setting("Twitch Response","True")
	else:
		print("⚠️ Twitch API servers could not be contacted. Offline or blocked.")
		#twitch_reachability_label.text = "Twitch API: Unreachable ❌"
		#twitch_reachability_label.add_theme_color_override("font_color", Color.DARK_RED)
		GlobalSystem.save_custom_setting("Twitch Response","false")


# --- NAVIGATION CONTROLS ---

func _on_host_btn_pressed() -> void:
	main_menu_container.visible = false
	main_menu_background.visible = false
	host_menu_container.visible = true

func _on_player_btn_pressed() -> void:
	print("🎮 Player App client initialization...")
	get_tree().change_scene_to_file("res://player_title_screen.tscn")

func _on_exit_game_btn_pressed() -> void:
	get_tree().quit()

func _on_studio_setup_btn_pressed() -> void:
	host_menu_container.visible = false
	main_menu_background.visible = false
	studio_setup_container.visible = true

func _on_start_studio_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://main_studio.tscn")

func _on_game_settings_btn_pressed() -> void:
	print("⚙️ Opening Game Settings sub-menu...")

func _on_host_back_btn_pressed() -> void:
	host_menu_container.visible = false
	main_menu_container.visible = true
	main_menu_background.visible = true

func _on_setup_back_btn_pressed() -> void:
	studio_setup_container.visible = false
	host_menu_container.visible = true
	main_menu_background.visible = true


# --- LOCAL FILE STORAGE PROFILE MANAGEMENT (ConfigFile) ---

func _on_save_settings_btn_pressed() -> void:
	var config = ConfigFile.new()
	
	config.set_value("StudioSetup", "max_players", player_count_spin.value)
	config.set_value("StudioSetup", "mod_count", mod_count_spin.value)
	config.set_value("StudioSetup", "dual_monitor", dual_monitor_check.button_pressed)
	config.set_value("StudioSetup", "separate_windows", separate_windows_check.button_pressed)
	config.set_value("StudioSetup", "scoreboard_mode", score_mode_option.get_selected_id())
	config.set_value("StudioSetup", "twitch_chat", twitch_interact_check.button_pressed)
	
	config.set_value("ActiveGames", "game_trivia", game_1_check.button_pressed)
	config.set_value("ActiveGames", "game_typeracer", game_2_check.button_pressed)
	config.set_value("ActiveGames", "game_wheel", game_3_check.button_pressed)
	config.set_value("ActiveGames", "game_polls", game_4_check.button_pressed)
	
	var error = config.save(SAVE_PATH)
	if error == OK:
		print("💾 Studio config saved successfully to: ", OS.get_user_data_dir())
	else:
		print("⚠️ Error saving layout file. Code: ", error)

func load_studio_settings() -> void:
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)
	
	if error != OK:
		print("ℹ️ No profile save file detected. Using factory studio defaults.")
		return
		
	print("📂 Loading configured configuration profile...")
	player_count_spin.value = config.get_value("StudioSetup", "max_players", 32)
	mod_count_spin.value = config.get_value("StudioSetup", "mod_count", 2)
	dual_monitor_check.button_pressed = config.get_value("StudioSetup", "dual_monitor", false)
	separate_windows_check.button_pressed = config.get_value("StudioSetup", "separate_windows", false)
	
	var saved_score_id = config.get_value("StudioSetup", "scoreboard_mode", 0)
	score_mode_option.select(score_mode_option.get_item_index(saved_score_id))
	
	twitch_interact_check.button_pressed = config.get_value("StudioSetup", "twitch_chat", false)
	
	game_1_check.button_pressed = config.get_value("ActiveGames", "game_trivia", true)
	game_2_check.button_pressed = config.get_value("ActiveGames", "game_typeracer", true)
	game_3_check.button_pressed = config.get_value("ActiveGames", "game_wheel", true)
	game_4_check.button_pressed = config.get_value("ActiveGames", "game_polls", true)
	
func _input(event):
	if Input.is_key_pressed(KEY_KP_5) and Input.is_key_pressed(KEY_SHIFT):
		print("☢️ EMERGENCY FAIL-SAFE TRIPPED! Closing environment down...")
		get_tree().quit()

# Checking for twitch auth token
func check_existing_twitch_authorization() -> bool:
	# 1. Ensure the Twitcher instance is loaded and active
	if twitch_addon == null:
		print("⚠️ Twitcher addon is not initialized yet.")
		return false
		
	# 2. Check Twitcher's built-in authorization properties
	var is_linked: bool = false
	if twitch_addon.has_method("is_authenticated"):
		is_linked = twitch_addon.is_authenticated()
	elif "is_authenticated" in twitch_addon:
		is_linked = twitch_addon.is_authenticated

	# 3. Process the result and handle user profiles
	if is_linked:
		var username = "Streamer"
		if "username" in twitch_addon:
			username = twitch_addon.username
		elif twitch_addon.has_method("get_username"):
			username = twitch_addon.get_username()
			
		print("✅ Valid Twitch session found! Automatically logged in as: ", username)
		return true
	else:
		print("🔗 No active Twitch token found. Authorization required.")
		return false
