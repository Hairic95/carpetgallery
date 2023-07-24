extends BaseComponent

var kbm_up = KEY_W
var kbm_down = KEY_S
var kbm_left = KEY_A
var kbm_right = KEY_D

var kbm_h_dir = 0
var kbm_v_dir = 0
var move_dir = Vector2()

func _physics_process(delta):
	kbm_h_dir = (-1 if Input.is_key_pressed(kbm_left) else 0) + (1 if Input.is_key_pressed(kbm_right) else 0)
	kbm_v_dir = (-1 if Input.is_key_pressed(kbm_up) else 0) + (1 if Input.is_key_pressed(kbm_down) else 0)
	move_dir = Vector2(kbm_h_dir, kbm_v_dir)
