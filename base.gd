extends StaticBody2D

@export var is_ally: bool = true  
@export var max_hp: int = 500   
var is_base = true  

# 폐허 이미지 불러오기
var destroyed_texture = preload("res://asset/Castle_Destroyed.png")

# 필수 노드 연결
@onready var hp_bar = get_node_or_null("ProgressBar")
@onready var sprite = $Sprite2D

# 체력 변경 시 체력바도 같이 움직이도록 세팅
var current_hp: int:
	set(value):
		current_hp = value
		print(name, " 체력 변경됨: ", current_hp)
		
		# 체력이 깎일 때마다 게이지 반영
		if hp_bar:
			hp_bar.value = current_hp
			
		if current_hp <= 0:
			destroy_base()

func _ready():
	# 현재 체력을 채우기 전에, 체력바의 '최대치'를 500으로 먼저 늘려주어야 합니다!
	if hp_bar:
		hp_bar.max_value = max_hp
		
	current_hp = max_hp

func destroy_base():
	print(name, " 기지가 파괴되었습니다!")
	
	# 1. 이미지를 파괴된 폐허 이미지로 즉시 교체
	if sprite and destroyed_texture:
		sprite.texture = destroyed_texture
		
	# 2. 기지가 부서졌으니 머리 위 체력바는 숨기기
	if hp_bar:
		hp_bar.visible = false
	
	# 3. 유닛들이 파괴된 기지를 무시하고 지나가도록 충돌 해제
	set_collision_layer_value(2, false) 
	set_collision_layer_value(3, false) 
	set_collision_mask_value(2, false)
	set_collision_mask_value(3, false)
	
	# 4. 게임 오버 실행
	if get_tree().current_scene.has_method("game_over"):
		get_tree().current_scene.game_over(is_ally)

func take_damage(amount):
	current_hp -= amount
