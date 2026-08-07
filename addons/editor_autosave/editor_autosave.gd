extends EditorPlugin

## Editor-side safety net for scene edits. This never writes gameplay progress.
## The public EditorInterface API can save scenes, but does not expose a
## supported way for plugins to flush unsaved external script-editor buffers.
const AUTOSAVE_INTERVAL_SECONDS: float = 60.0
const PANEL_TITLE := "Editor Autosave"

var _timer: Timer
var _timer_callback: Callable
var _panel: PanelContainer
var _status_label: Label

func _enter_tree() -> void:
	_panel = PanelContainer.new()
	_panel.name = "EditorAutosaveStatus"
	_status_label = Label.new()
	_status_label.text = "Autosave do editor ativo: cenas a cada 60 segundos."
	_status_label.tooltip_text = "Guarda todas as cenas abertas/modificadas. Buffers de scripts não são persistíveis pela API pública do EditorPlugin."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_status_label)
	add_control_to_bottom_panel(_panel, PANEL_TITLE)

	_timer = Timer.new()
	_timer.name = "EditorAutosaveTimer"
	_timer.wait_time = AUTOSAVE_INTERVAL_SECONDS
	_timer.one_shot = false
	_timer_callback = Callable(self, "_on_autosave_timeout")
	_timer.timeout.connect(_timer_callback)
	add_child(_timer)
	_timer.start()

	_report_status("Ativo — próxima gravação de cenas em 60 segundos.")
	print("[EditorAutosave] Ativo; intervalo explícito: %.0f segundos." % AUTOSAVE_INTERVAL_SECONDS)

func _exit_tree() -> void:
	# Make one final best-effort scene save before the plugin is removed or the
	# editor shuts down. This is editor work protection, not a runtime save.
	_save_all_scenes("encerramento do plugin")

	if is_instance_valid(_timer):
		_timer.stop()
		if _timer.timeout.is_connected(_timer_callback):
			_timer.timeout.disconnect(_timer_callback)
		_timer.queue_free()
		_timer = null
	_timer_callback = Callable()
	if is_instance_valid(_panel):
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()
		_panel = null
	_status_label = null
	print("[EditorAutosave] Desativado e limpo.")

func _on_autosave_timeout() -> void:
	_save_all_scenes("temporizador de 60 segundos")

func _save_all_scenes(reason: String) -> void:
	var editor_interface := get_editor_interface()
	if editor_interface == null:
		_report_status("Autosave: interface do editor indisponível; nenhuma cena foi gravada.")
		push_warning("[EditorAutosave] Interface do editor indisponível durante %s." % reason)
		return

	# save_all_scenes() is the supported public API and saves all open scenes.
	editor_interface.save_all_scenes()
	_report_status("Cenas guardadas (%s). Buffers de scripts: limitação da API pública." % reason)
	print("[EditorAutosave] Cenas abertas guardadas — %s." % reason)

func _report_status(message: String) -> void:
	if is_instance_valid(_status_label):
		_status_label.text = message

