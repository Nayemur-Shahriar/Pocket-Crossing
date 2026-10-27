class_name SceneFade
extends CanvasLayer
## One bounded, cancellable presentation transition. No ownership of gameplay.
signal finished
var settle_frames := 0
var physics_ready := false
var busy := false
var stage := 0
var elapsed := 0.0
var pending: Callable
var veil: ColorRect
var caption: Label
func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	veil = ColorRect.new()
	veil.color = Color("162e38")
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	caption = Label.new()
	caption.text = "LOADING…"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 24)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.add_child(caption)
	cancel()
func begin(callback: Callable) -> void:
	if busy: return
	pending = callback
	busy = true
	stage = 0
	elapsed = 0.0
	veil.modulate.a = 0.0
	veil.show()
	caption.hide()
	physics_ready = false
	set_physics_process(true)
	set_process(true)
func cancel() -> void:
	var was_busy := busy
	busy = false
	pending = Callable()
	if is_instance_valid(veil): veil.hide()
	set_process(false)
	set_physics_process(false)
	if was_busy:finished.emit()
func _physics_process(_delta: float) -> void:
	if stage == 3:physics_ready = true
func _process(delta: float) -> void:
	elapsed += delta
	match stage:
		0:
			veil.modulate.a = minf(1.0, elapsed / 0.20)
			if elapsed >= 0.20:
				stage = 1
				caption.show()
		1:
			# Keep an opaque rendered frame before synchronous map preparation.
			stage = 2
		2:
			var callback := pending
			pending = Callable()
			stage = 3
			settle_frames = 0
			physics_ready = false
			elapsed = 0.0
			if callback.is_valid(): callback.call()
			caption.hide()
		3:
			# Settle deferred frees, camera/weather and physics while fully covered.
			settle_frames += 1
			veil.modulate.a = 1.0
			if settle_frames >= 2 and physics_ready:
				stage = 4
				elapsed = 0.0
		4:
			veil.modulate.a = maxf(0.0, 1.0 - elapsed / 0.22)
			if elapsed >= 0.22: cancel()
