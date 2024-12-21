extends RigidBody3D

@export_range(0, 1, 1, "or_greater", "suffix:m/s^2") var MAX_ACCELERATION: float
@export_range(0, 1, 1, "or_greater", "suffix:deg/s^2") var MAX_TURN_TORQUE: float

func force_for_accel(accel: Vector3) -> Vector3:
	return self.mass * accel

func _physics_process(delta: float) -> void:
	# Point the mesh along the velocity vector
	if !self.linear_velocity.is_zero_approx():
		$Body.look_at(self.position + self.linear_velocity)

	# Thrust
	var thrust_acc = MAX_ACCELERATION * (
		Input.get_action_strength("forward_thrust") * Vector3.FORWARD
		+ Input.get_action_strength("reverse_thrust") * Vector3.BACK
		+ Input.get_action_strength("turn_left") * Vector3.LEFT
		+ Input.get_action_strength("turn_right") * Vector3.RIGHT
	)

	# Turn
	var input_turn_torque = deg_to_rad(MAX_TURN_TORQUE) * (
		# Up/Down = Pitch Around Left-Right Axis
		#Input.get_action_strength("turn_up") * Vector3.LEFT
		#+ Input.get_action_strength("turn_down") * Vector3.RIGHT
		# Left/Right = Yaw Around (global) Up-Down Axis
		+ Input.get_action_strength("turn_left") * Vector3.UP
		+ Input.get_action_strength("turn_right") * Vector3.DOWN
	)

	

	var final_force = force_for_accel(thrust_acc)
	#var final_torque = force_for_accel(input_turn_torque)

	self.apply_central_force(self.basis * final_force)
	#self.apply_torque(self.basis * final_torque)
