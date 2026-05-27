extends Camera2D

var is_dragging: bool = false

func _input(event):
	# 1. 마우스 왼쪽 버튼(또는 오른쪽 버튼) 클릭 감지
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			
	# 2. 클릭한 상태로 마우스를 움직이면 카메라 위치 이동
	elif event is InputEventMouseMotion and is_dragging:
		# event.relative는 마우스가 움직인 거리를 뜻합니다.
		# 화면이 마우스와 반대로 따라오게 하려면 빼기(-=)를 해줍니다.
		position -= event.relative / zoom
