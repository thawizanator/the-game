extends Control

@onready var status_label: Label = $Background/CenterLayout/StatusLableContainer/StatusLabel
@onready var loading_bar: ProgressBar = $Background/CenterLayout/MarginContainer/LoadingBar
@onready var disclaimer_text: Label = $Background/CenterLayout/DisclaimerBox/DisclaimerScroll/MarginContainer/DisclaimerText
@onready var version_label: Label = $VersionContainer/VersionLabel

var is_loaded: bool = false

# Define the percentage of the monitor size you want (e.g., 0.9 for 90%)
const SCREEN_PERCENTAGE = 0.9

# Custom Rich text layout for your warning sequence
const WARNING_TEXT = (
	"⚠️ SYSTEM WARNING & LIABILITY WAIVER ⚠️\n\n" +
	"This is an unstable educational test build. The engine is heavily broken as we are learning " +
	"the development ropes. By pressing SPACEBAR, you agree that you are running this software " +
	"entirely AT YOUR OWN RISK. Not all buttons, layouts, options, or server handshakes are functional.\n\n" +
	"💥 FAIL-SAFE ESCAPE BLOCK:\n" +
	"If you get permanently soft-locked or trapped in a broken menu compartment, force kill the game " +
	"instantly by pressing: [Numpad 5 + Left Shift]\n\n" +
	"🛠️ TICKETING & DEVELOPER ACCESS:\n" +
	"Have questions, concepts, bugs, or feedback? Head over to Twitch or type !discord in the chat " +
	"to join our server. Open a ticket in the help section to unlock access to the game-dev channel. " +
	"Yes, it's a complicated maze, but if you can follow these rules, you're ready for the studio booth!"
)

func _ready() -> void:
	# 1. SCALE AND CENTER THE WINDOW
	var monitor_size = DisplayServer.screen_get_size()
	
	# Calculate the target window size based on the percentage
	var target_width = int(monitor_size.x * SCREEN_PERCENTAGE)
	var target_height = int(monitor_size.y * SCREEN_PERCENTAGE)
	
	# Set the new window size
	DisplayServer.window_set_size(Vector2i(target_width, target_height))
	
	# Center the resized window on the screen
	var screen_idx = DisplayServer.window_get_current_screen()
	var screen_center = DisplayServer.screen_get_position(screen_idx) + (DisplayServer.screen_get_size(screen_idx) / 2)
	var window_pos = screen_center - (Vector2i(target_width, target_height) / 2)
	DisplayServer.window_set_position(window_pos)
	
	# Set baseline readout properties
	version_label.text = GlobalSystem.dev_build_version
	loading_bar.value = 0
	status_label.text = "Initializing Game Studio Environment..."
	disclaimer_text.text = WARNING_TEXT
	
	# Simulate connection timer delay
	var timer = Timer.new()
	timer.wait_time = 0.05
	timer.autostart = true
	timer.connect("timeout", Callable(self, "_on_loading_tick").bind(timer))
	add_child(timer)

func _on_loading_tick(timer: Timer) -> void:
	if loading_bar.value < 100:
		loading_bar.value += 2
	else:
		timer.stop()
		is_loaded = true
		status_label.text = "🟢 SYSTEM READY. PRESS SPACEBAR TO RISK ENTRY..."

# MASTER INPUT PROCESSOR: Bypasses container focus completely
func _input(event):
	# 1. The Nuclear Option / Fail-Safe Kill Combination 
	if Input.is_key_pressed(KEY_KP_5) and Input.is_key_pressed(KEY_SHIFT):
		print("☢️ EMERGENCY FAIL-SAFE TRIPPED! Closing environment down...")
		get_tree().quit()
		
	# 2. Proceed Loop
	if is_loaded and event.is_action_pressed("ui_accept"):
		status_label.text = "Launching Main Title Studio..."
		await get_tree().create_timer(0.3).timeout
		get_tree().change_scene_to_file("res://title_screen.tscn")
