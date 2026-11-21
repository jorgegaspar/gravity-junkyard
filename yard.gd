extends Control

signal impulse_requested(point: Vector2)

const PLANET_RADIUS := 34.0
const SCRAP_COLORS := [Color("#f5b66a"), Color("#80dfce"), Color("#b7a5ff")]

var planet := Vector2.ZERO
var velocity := Vector2.ZERO
var scrap: Array[Vector2] = []
var scrap_velocity: Array[Vector2] = []
var caught := 0
var spent := 0
var upgrades := 0
var cooldown := 0.0
var speed := 1.0
var active := false
var rng := RandomNumberGenerator.new()


func start_sector(count: int, seed_value: int) -> void:
	rng.seed = seed_value
	planet = size * 0.5
	velocity = Vector2.ZERO
	scrap.clear()
	scrap_velocity.clear()
	caught = 0
	spent = 0
	upgrades = 0
	cooldown = 0.0
	active = true
	for index in count:
		var angle := TAU * (index + rng.randf_range(-0.3, 0.3)) / count
		var direction := Vector2.from_angle(angle)
		var orbit := minf(size.x, size.y) * rng.randf_range(0.26, 0.45)
		scrap.append(planet + direction * orbit)
		scrap_velocity.append(direction.orthogonal() * rng.randf_range(10.0, 30.0))
	queue_redraw()


func impulse(point: Vector2) -> void:
	if not active or cooldown > 0.0 or planet.distance_to(point) < 10.0:
		return
	velocity = (velocity + planet.direction_to(point) * 255.0).limit_length(420.0)
	cooldown = 0.65


func upgrade_cost() -> int:
	return 3 + upgrades * 3


func buy_upgrade() -> void:
	var cost := upgrade_cost()
	if active and upgrades < 3 and caught - spent >= cost:
		spent += cost
		upgrades += 1


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		impulse_requested.emit(event.position)
		accept_event()


func _physics_process(delta: float) -> void:
	if not active:
		return
	var step := delta * speed
	cooldown = maxf(0.0, cooldown - step)
	velocity *= exp(-2.6 * step)
	if upgrades > 0 and not scrap.is_empty() and cooldown <= 0.0:
		var closest := scrap[0]
		for piece in scrap:
			if planet.distance_squared_to(piece) < planet.distance_squared_to(closest):
				closest = piece
		velocity += planet.direction_to(closest) * 70.0 * upgrades * step
	planet = (planet + velocity * step).clamp(
		Vector2.ONE * PLANET_RADIUS, size - Vector2.ONE * PLANET_RADIUS
	)
	for index in range(scrap.size() - 1, -1, -1):
		var offset := planet - scrap[index]
		var distance := offset.length()
		if distance < PLANET_RADIUS + 7.0:
			scrap.remove_at(index)
			scrap_velocity.remove_at(index)
			caught += 1
			continue
		var attraction := 700000.0 * (1.0 + upgrades * 0.55)
		scrap_velocity[index] += offset.normalized() * attraction / (distance * distance) * step
		scrap_velocity[index] = (scrap_velocity[index] * exp(-0.75 * step)).limit_length(210.0)
		var position_next := scrap[index] + scrap_velocity[index] * step
		var bounded := position_next.clamp(Vector2.ONE * 8.0, size - Vector2.ONE * 8.0)
		if position_next.x != bounded.x:
			scrap_velocity[index].x *= -0.6
		if position_next.y != bounded.y:
			scrap_velocity[index].y *= -0.6
		scrap[index] = bounded
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#101b35"))
	for index in 65:
		var star := Vector2(fmod(index * 0.618, 1.0), fmod(index * 0.371, 1.0)) * size
		draw_circle(star, 1.4 if index % 7 == 0 else 0.8, Color("#536388"))
	if planet == Vector2.ZERO:
		return
	for radius in [58.0, 86.0, 114.0]:
		draw_arc(planet, radius, 0.0, TAU, 64, Color("#384977"), 1.0, true)
	draw_circle(planet, PLANET_RADIUS + 5.0, Color("#393e80"), true, -1.0, true)
	draw_circle(planet, PLANET_RADIUS, Color("#886cf4"), true, -1.0, true)
	draw_circle(planet + Vector2(-10, -9), 13.0, Color("#ad9aff"), true, -1.0, true)
	draw_circle(planet + Vector2(13, 12), 8.0, Color("#6453bb"), true, -1.0, true)
	for index in scrap.size():
		var piece := scrap[index]
		var diamond := PackedVector2Array([
			piece + Vector2(0, -7), piece + Vector2(7, 0),
			piece + Vector2(0, 7), piece + Vector2(-7, 0)
		])
		draw_colored_polygon(diamond, SCRAP_COLORS[index % SCRAP_COLORS.size()])
