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


func _ready() -> void:
	print("🎬 Title Screen Room Initialized...")
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
	
	# hello for changes
	
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
