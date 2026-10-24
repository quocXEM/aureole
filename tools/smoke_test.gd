extends SceneTree
## Headless smoke: menu → game → drop ×3 → must not error.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("SMOKE: start")
	# Parse check
	var scr: GDScript = load("res://scripts/game/stack_game.gd")
	if scr == null:
		push_error("SMOKE FAIL: stack_game load null")
		quit(1)
		return
	print("SMOKE: stack_game parsed")

	var err := change_scene_to_file("res://scenes/main_menu.tscn")
	if err != OK:
		push_error("SMOKE FAIL: menu %s" % err)
		quit(1)
		return
	print("SMOKE: menu ok")
	await create_timer(0.35).timeout

	err = change_scene_to_file("res://scenes/game.tscn")
	if err != OK:
		push_error("SMOKE FAIL: game %s" % err)
		quit(1)
		return
	await create_timer(0.5).timeout
	var root := current_scene
	if root == null or not root.has_method("_try_drop"):
		push_error("SMOKE FAIL: game scene missing _try_drop (script failed?)")
		quit(1)
		return
	print("SMOKE: game ok")
	for i in 3:
		root.call("_try_drop")
		print("SMOKE: drop ", i + 1)
		await create_timer(0.4).timeout
	print("SMOKE: PASS")
	quit(0)
