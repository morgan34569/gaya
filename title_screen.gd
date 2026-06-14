extends Control
@onready var ui_click_sound = get_node_or_null("UIClickSound")
func _ready():
	pass
	

# [게임 시작] 버튼 눌렀을 때
func _on_start_button_pressed():
	if ui_click_sound: 
		ui_click_sound.play()
		
	var tween = create_tween()
	tween.tween_property($TitleBGM, "volume_db", -80.0, 1.0)
	await tween.finished 
	get_tree().change_scene_to_file("res://WorldMap.tscn")


func _on_setting_button_pressed():
	if ui_click_sound: ui_click_sound.play()
	SettingUI.open_settings()

# [종료] 아이콘 버튼 눌렀을 때
func _on_quit_button_pressed():
	if ui_click_sound: ui_click_sound.play()
	await ui_click_sound.finished
	get_tree().quit() # 게임 종료
