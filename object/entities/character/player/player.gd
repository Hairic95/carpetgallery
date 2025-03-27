extends NetworkBody
class_name NetworkPlatformerPlayer

#var muzzle_effect_reference = load("res://src/effects/MuzzleEffect.tscn")

const SPEED = 120
const DASH_SPEED = 260

var can_dash = true

var health = 5

var pushboxes = []

var dash_direction = Vector2.ZERO

var current_state = "Idle"

@onready var anim = $Sprites/Anim

var dash_time_max = .28
var dash_timer = .0

var latest_direction := Vector2(1, 0)

var can_shoot = true


var target_weapon_rotation = 0

var auto_setup_components = true


func _physics_process(delta):
	super(delta)
	if is_client_owner():
		
		movement_direction = Vector2.ZERO
		
		if active:
			if current_state != "Dashing":
				# MOVEMENT
				if Input.is_action_pressed("move_left"):
					movement_direction.x = -1
					latest_direction.x = -1
				if Input.is_action_pressed("move_right"):
					movement_direction.x = 1
					latest_direction.x = 1
				if Input.is_action_pressed("move_up"):
					movement_direction.y = -1
					latest_direction.y = -1
				if Input.is_action_pressed("move_down"):
					movement_direction.y = 1
					latest_direction.y = 1
				
				latest_direction = latest_direction.normalized()
				#if Input.is_action_just_pressed("shoot"):
				#	shoot()
				if Input.is_action_just_pressed("dash") && can_dash:
					set_state("Dashing")
					dash_direction = latest_direction
			elif current_state == "Crouching" && !Input.is_action_pressed("move_down"):
				set_state("Idle")
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
		var result_movement = Vector2.ZERO
		if current_state != "Crouching" && current_state != "Dashing":
			# Horizontal obstacle check and movement
			#var collider_data = move_and_collide(movement_direction * SPEED * delta, true, true, true)
			#if !collider_data:
			velocity = movement_direction * SPEED
			result_movement = move_and_slide()
			
			if get_global_mouse_position().x < global_position.x:
				$Sprites.scale.x = -1
			else:
				$Sprites.scale.x = 1
			
			# Animation
			if abs(movement_direction) != Vector2.ZERO:
				set_state("Move")
			else:
				set_state("Idle")
			
		elif current_state == "Dashing":
			
			var stop_dash = false
			var collider_data = move_and_collide(dash_direction.normalized() * DASH_SPEED * delta, true, true, true)
			if !collider_data:
				velocity = dash_direction.normalized() * DASH_SPEED
				result_movement = move_and_slide()
			else:
				stop_dash = true
			if dash_timer >= dash_time_max:
				stop_dash = true
			else:
				dash_timer += delta
			
			if stop_dash:
				dash_timer = 0
				set_state("Idle")
		
		if active:
			pass
			#Input.set_custom_mouse_cursor(load("res://assets/textures/platformer/cursor_x3.png"))
		else:
			pass
			#Input.set_custom_mouse_cursor(null)
	else:
		if GlobalState.player.map_coordinates == map_coordinates:
			global_position = lerp(global_position, target_position, .3)
		else:
			global_position = Vector2(-100, -100)

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

func _on_PushBox_area_entered(area):
	if area.is_in_group("pushbox"):
		if !pushboxes.has(area):
			pushboxes.append(area)

func _on_PushBox_area_exited(area):
	if area.is_in_group("pushbox"):
		if pushboxes.has(area):
			pushboxes.erase(area)

func hurt(damage):
	"""
	health = max(0, health - damage)
	EventBus.emit_signal("player_health_update", health)
	if health == 0:
		active = false
		EventBus.emit_signal("entity_death", {
			"type": NetworkConstants.GenericAction_EntityDeath,
			"owner_id": owner_uuid,
			"entity_id": entity_uuid,
			"entity_type": NetworkConstants.EntityType_Player,
		})
		NetworkSocket.send_message({
			"type": NetworkConstants.GenericAction_EntityDeath,
			"owner_id": owner_uuid,
			"entity_id": entity_uuid,
			"entity_type": NetworkConstants.EntityType_Player,
		})
		queue_free()
"""
func _on_Hitbox_area_entered(area):
	var area_parent = area.get_parent()
	"""
	if area_parent is NetworkBullet:
		if is_client_owner():
			if area_parent.owner_uuid != owner_uuid:
				hurt(area_parent.damage)
				area_parent.destroy_bullet()
		else:
			if area_parent.owner_uuid != owner_uuid:
				area_parent.destroy_bullet(false)
	

func shoot():
	var starting_position = $Sprites/PlayerWeapon/BulletSpawn.global_position
	var bullet_direction = (get_global_mouse_position() - starting_position).normalized()
	EventBus.emit_signal("create_bullet", Constants.BulletCategories_Regular, starting_position + bullet_direction * 5, bullet_direction)
	var new_muzzle_effect = muzzle_effect_reference.instance()
	new_muzzle_effect.rotation = bullet_direction.angle()
	EventBus.emit_signal("create_effect", new_muzzle_effect, starting_position + bullet_direction * 5)
	EventBus.emit_signal("create_screenshake", 6)
	
	NetworkSocket.send_message({
		"type": Constants.GenericAction_EntityMiscOneOff,
		"entity_id": entity_uuid,
		"one_off_type": "play_shoot",
	})
	$ShootSFX.stop()
	$ShootSFX.pitch_scale = .8 + randf() * .3
	$ShootSFX.play()
"""

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

func remove_component(component):
	$Components.remove(component)

func get_component(type) -> BaseComponent:
	return %Components.get_component(type)

func reset_momentum():
	movement_direction = Vector2.ZERO

func set_username(username: String):
	$PlayerName.text = username
