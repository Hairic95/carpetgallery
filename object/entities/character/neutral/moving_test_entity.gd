extends NetworkBody
class_name MovingTestEntity

#var muzzle_effect_reference = load("res://src/effects/MuzzleEffect.tscn")

const SPEED = 60
const DASH_SPEED = 260

var can_dash = true

var health = 5

var dash_direction = Vector2.ZERO

var current_state = "MovingUp"

@onready var anim = $Sprites/Anim

var dash_time_max = .28
var dash_timer = .0
var latest_direction := Vector2(1, 0)
var can_shoot = true
var target_weapon_rotation = 0

var is_new = false

func _ready():
	super()
	anim.play("Running")
	if is_new:
		entity_uuid = uuid.v4()
		NetworkSocket.send_add_entity({
			"id": entity_uuid,
			"type": "test",
			"position": {
				"x": global_position.x,
				"y": global_position.y
			},
			"map_coordinates":  {
				"x": map_coordinates.x,
				"y": map_coordinates.y
			},
		})

func _physics_process(delta):
	super(delta)
	if is_client_owner():
		
		movement_direction = Vector2.ZERO
		
		if active:
			if current_state == "MovingUp":
				movement_direction.y = -1
			elif current_state == "MovingDown":
				movement_direction.y = 1
			
			#var mouse_distance_vector = ($Sprites/PlayerWeapon.get_global_mouse_position() - global_position).normalized()
			#if mouse_distance_vector.x < 0:
			#	$Sprites/PlayerWeapon.rotation = -(mouse_distance_vector).angle() + PI
			#elif mouse_distance_vector.x > 0:
			#	$Sprites/PlayerWeapon.rotation = (mouse_distance_vector).angle()
			
		movement_direction = movement_direction.normalized()
		#var push_force = Vector2.ZERO
		#for pushbox in pushboxes:
		#	push_force += (global_position - pushbox.global_position).normalized() * 100
		#	push_force.y = 0
		var collider_data = move_and_collide(movement_direction * SPEED * delta, true, true, true)
		if collider_data:
			if current_state == "MovingUp":
				$Sprites.scale.x = -1
				current_state = "MovingDown"
			else:
				$Sprites.scale.x = 1
				current_state = "MovingUp"
		else:
			velocity = SPEED * movement_direction
			move_and_slide()
			
	else:
		global_position = lerp(global_position, target_position, .3)
	

func set_state(new_state):
	if new_state != current_state:
		current_state = new_state
		if anim != null:
			match(new_state):
				"Idle":
					anim.play("Idle")
				"Move":
					anim.play("Running")
				"Jumping":
					anim.play("Jumping")
				"Falling":
					anim.play("Falling")
				"Crouching":
					anim.play("Crouching")
		
		if is_client_owner():
			NetworkSocket.send_message({
				"entity_id": entity_uuid,
				"type": NetworkConstants.GenericAction_EntityUpdateState,
				"state": current_state,
			})

func send_hard_update_position():
	NetworkSocket.send_message({
		"entity_id": entity_uuid,
		"type": NetworkConstants.GenericAction_EntityHardUpdatePosition,
		"position": {
			"x": global_position.x,
			"y": global_position.y,
		},
	})

func remote_entity_update_state(data):
	if data.entity_id == entity_uuid:
		super(data)
		set_state(data.state)

func remote_entity_misc_process_data(data):
	if data.entity_id == entity_uuid:
		super(data)
		$Sprites.scale.x = data.facing
		target_weapon_rotation = data.weapon_rotation

func remote_entity_misc_one_off(data):
	if data.entity_id == entity_uuid:
		if data.one_off_type == "play_shoot":
			$ShootSFX.stop()
			$ShootSFX.pitch_scale = .8 + randf() * .3
			$ShootSFX.play()
		super(data)

func set_web_id(_web_id, _entity_id):
	entity_uuid = _entity_id
	owner_uuid = _web_id

func remote_entity_update_flip(data):
	if !is_client_owner():
		$Sprites.scale.x = data.flip

func get_component(type) -> BaseComponent:
	return %Components.get_component(type)

func reset_momentum():
	movement_direction = Vector2.ZERO
