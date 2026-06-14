extends CanvasLayer

var bgm_bus_index = AudioServer.get_bus_index("BGM")
var sfx_bus_index = AudioServer.get_bus_index("SFX")
@onready var ui_click_sound = get_node_or_null("UIClickSound")
@onready var panel = $Panel 
@onready var bgm_slider = $Panel/BGMSlider
@onready var sfx_slider = $Panel/SFXSlider

func _ready():
	# 게임 시작 시 일단 화면에서 숨겨둡니다.
	panel.visible = false
	
	# 슬라이더 위치 초기화
	bgm_slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(bgm_bus_index)))
	sfx_slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_index)))

# --- [어느 씬에서나 부를 수 있는 열기/닫기 함수] ---
func open_settings():
	panel.visible = true
	get_tree().paused = true # 설정창을 열면 게임 일시 정지

func close_settings():
	if ui_click_sound: ui_click_sound.play()
	panel.visible = false
	get_tree().paused = false # 닫으면 게임 재개

# --- [슬라이더 및 버튼 시그널] ---
func _on_bgm_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(bgm_bus_index, linear_to_db(value))

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value))
	if $SFXTestSound.playing == false: 
		$SFXTestSound.play()
