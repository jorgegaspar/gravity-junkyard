extends Control

const Yard = preload("res://yard.gd")
const SECTORS := ["Cintura de Detritos", "Cemitério Orbital", "Órbita Exterior"]
const TARGETS := [14, 24, 34]

var yard := Yard.new()
var sector := 0
var status: Label
var hint: Label
var title: Label
var progress: ProgressBar
var upgrade: Button
var acceleration: Button
var next: Button


func _ready() -> void:
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)

	var brand := Label.new()
	brand.text = "GRAVITY JUNKYARD"
	brand.add_theme_font_size_override("font_size", 28)
	stack.add_child(brand)

	title = Label.new()
	title.add_theme_color_override("font_color", Color("#bab0ff"))
	stack.add_child(title)
	status = Label.new()
	stack.add_child(status)

	progress = ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 8
	stack.add_child(progress)

	yard.custom_minimum_size.y = 300
	yard.size_flags_vertical = Control.SIZE_EXPAND_FILL
	yard.impulse_requested.connect(yard.impulse)
	stack.add_child(yard)

	hint = Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.y = 48
	stack.add_child(hint)

	upgrade = add_button(stack, yard.buy_upgrade)
	acceleration = add_button(stack, toggle_speed)
	next = add_button(stack, next_sector)
	next.hide()

	await get_tree().process_frame
	start_sector()


func add_button(parent: Container, action: Callable) -> Button:
	var button := Button.new()
	button.custom_minimum_size.y = 48
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func start_sector() -> void:
	title.text = "Setor %d/%d  ·  %s" % [sector + 1, SECTORS.size(), SECTORS[sector]]
	progress.max_value = TARGETS[sector]
	yard.start_sector(TARGETS[sector] + 4, 321 + sector * 17)


func toggle_speed() -> void:
	yard.speed = 2.0 if yard.speed == 1.0 else 1.0


func next_sector() -> void:
	sector = (sector + 1) % SECTORS.size()
	if sector == 0:
		yard.speed = 1.0
	next.hide()
	await get_tree().process_frame
	start_sector()


func _process(_delta: float) -> void:
	if status == null or not yard.active:
		return
	var target: int = TARGETS[sector]
	status.text = "Recolha %d/%d    ·    Sucata disponível %d" % [
		mini(yard.caught, target), target, yard.caught - yard.spent
	]
	progress.value = yard.caught
	upgrade.text = "Piloto automático máx." if yard.upgrades == 3 else (
		"Melhorar piloto automático (%d)" % yard.upgrade_cost()
	)
	upgrade.disabled = yard.upgrades == 3 or yard.caught - yard.spent < yard.upgrade_cost()
	acceleration.text = "Velocidade %d×" % int(yard.speed)
	if yard.caught >= target:
		yard.active = false
		upgrade.disabled = true
		hint.text = "Pátio recuperado!" if sector == SECTORS.size() - 1 else "Setor concluído."
		next.text = "Jogar de novo" if sector == SECTORS.size() - 1 else "Próximo setor"
		next.show()
	elif yard.cooldown > 0.0:
		hint.text = "Impulso a recarregar…"
	else:
		hint.text = "Toca no campo para impulsionar o planeta nessa direção."
