extends "res://base_unit.gd"


# 화살 씬 불러오기
var arrow_scene = preload("res://arrow.tscn")

# ---------------------------------------------------------
# [궁수 전용 기능] 화살 쏘기
#AnimationPlayer의 애니메이션 도중 특정 프레임에 맞춰 이 함수를 실행하게 됩니다.
# ---------------------------------------------------------
func shoot_arrow():
	
	$AttackSound.play()
	# 1. 화살 인스턴스(복제본) 생성
	var arrow = arrow_scene.instantiate()
	
	# 2. 화살의 시작 위치를 궁수의 현재 위치로 설정
	arrow.global_position = self.global_position 
	
	# 3. 부모(BaseUnit.gd)에 선언된 아군/적군 변수(is_ally)를 화살에게 전달
	arrow.is_ally_arrow = self.is_ally
	arrow.direction = 1 if self.is_ally else -1
	
	# 4. 현재 화면(메인 씬)에 화살을 추가하여 날아가게 만듦
	get_tree().current_scene.add_child(arrow)
