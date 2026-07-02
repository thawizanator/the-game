extends Node
# This script lives at the root level of the engine game tree.

# It can hold global flags or tracking stats too.
#var dev_build_version: String = "v0.4-Alpha"
# This variable will populate itself on application boot sequence
var dev_build_version: String = "v0.0.0-Fallback"

# One config file for everything
const SAVE_PATH = "user://studio_settings.cfg"


func _ready() -> void:
	# Read directly from Project Settings -> Config -> Version
	if ProjectSettings.has_setting("application/config/version"):
		dev_build_version = ProjectSettings.get_setting("application/config/version")
	else:
		dev_build_version = "v0.4-Alpha-Dev" # Safeguard fallback
		
	print("🚀 System Boot Successful. Operating Build Profile: ", dev_build_version)
	#ProjectSettings.
# Moving your emergency fail-safe key combo here removes duplication!
func check_emergency_kill() -> void:
	if Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_H) and Input.is_key_pressed(KEY_KP_5):
		print("☢️ GLOBAL OVERRIDE: Emergency system kill triggered.")
		get_tree().quit()

# Any utility function you write here is shared instantly
func print_diagnostic_log(message: String) -> void:
	print("[STUDIO ENGINE INTERACTION LOG]: ", message)

# Save new setting to CONFIG
func save_custom_setting(setting_key: String, setting_value: Variant) -> void:
	# 1. Initialize a temporary configuration processor object
	var config = ConfigFile.new()
	
	# 2. OPTIONAL but recommended: Load existing file settings so we preserve them
	if FileAccess.file_exists(SAVE_PATH):
		config.load(SAVE_PATH)
		
	# 3. Add or update your setting value inside a specific section block
	# Format: config.set_value("Section", "Key", Value)
	config.set_value("StudioCustom", setting_key, setting_value)
	
	# 4. Commit the modifications back into the local user folder storage directory
	var error = config.save(SAVE_PATH)
	
	# Verification validation logs
	if error == OK:
		print("💾 Saved custom property [", setting_key, ": ", setting_value, "] to configuration profile!")
	else:
		print("⚠️ Failed to write to config file. Error structure identifier code: ", error)
