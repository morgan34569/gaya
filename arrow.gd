extends Area2D

var speed: float = 300.0
var damage: int = 15
var direction: int = 1 # 1이면 오른쪽, -1이면 왼쪽
var is_ally_arrow: bool = true 
var is_raining: bool = false

func _ready():
	if is_raining:
		rotation_degrees = 45 
		speed = 800.0 
		# 💡 R 스킬 레벨에 따라 화살 1발당 데미지 대폭 증가 (80 ~ 최대 200)
		damage = 80 + ((Global.gen_r_level - 1) * 30)
	elif direction == -1:
		$Sprite2D.flip_h = true

func _process(delta):
	if is_raining:
		# 💡 궁극기 화살은 대각선(우측 하단)으로 빠르게 꽂힙니다.
		position += Vector2(1, 1).normalized() * speed * delta
		
		# 화면 아래로 너무 많이 떨어지면 메모리 확보를 위해 스스로 삭제합니다.
		if position.y > 1000:
			queue_free()
	else:
		# 기존 매 프레임 지정된 방향으로 날아가는 로직
		position.x += speed * direction * delta

# (주의: 우측 노드 탭에서 body_entered 시그널을 연결해야 발동합니다)
func _on_body_entered(body):
	if "current_hp" in body:
		# 만약 이 화살이 궁극기(is_raining)이고, 맞은 대상이 기지(is_base)라면?
		if is_raining and "is_base" in body and body.is_base == true:
			queue_free() # 데미지를 주지 않고 화살만 뿅! 하고 사라집니다.
			return       # 아래 데미지 계산 코드를 실행하지 않고 여기서 함수 종료!
			
		if body.is_ally != self.is_ally_arrow:
			body.current_hp -= damage
			print(body.name, "가 화살에 맞음! 남은 체력:", body.current_hp)
			queue_free() # 맞추면 화살 삭제
