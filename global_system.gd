extends Node
# This script lives at the root level of the engine game tree.

# It can hold global flags or tracking stats too.
#var dev_build_version: String = "v0.4-Alpha"
# This variable will populate itself on application boot sequence
var dev_build_version: String = "v0.0.0-Fallback"

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
