extends Resource
class_name MarketEvent

signal finished(event: MarketEvent)

@export var symbol: String = ""
@export var start_delay_range: Vector2i = Vector2i.ZERO
@export var stages: Array[MarketEventStage] = []

var _rng: RandomNumberGenerator
var _asset
var _start_minute: int = -1
var _stage_index: int = -1
var _stage_start_minute: int = 0
var _stage_duration: int = 0
var _stage_start_price: float = 0.0
var _stage_target_price: float = 0.0

func schedule(asset) -> void:
        _asset = asset
        _rng = RNGManager.market_event.get_rng()
        _start_minute = TimeManager.get_now_minutes() + _rng.randi_range(start_delay_range.x, start_delay_range.y)
        TimeManager.minute_passed.connect(_on_minute_passed)

func _on_minute_passed(current_minute: int) -> void:
        if current_minute < _start_minute:
                return
        if _stage_index == -1:
                _advance_stage()
        if _stage_index >= stages.size():
                TimeManager.minute_passed.disconnect(_on_minute_passed)
                emit_signal("finished", self)
                return
        var elapsed := current_minute - _stage_start_minute
        var t := float(elapsed) / float(_stage_duration)
        _asset.price = lerp(_stage_start_price, _stage_target_price, t)
        if elapsed >= _stage_duration:
                _asset.price = _stage_target_price
                _advance_stage()

func _advance_stage() -> void:
        _stage_index += 1
        if _stage_index >= stages.size():
                return
        var stage: MarketEventStage = stages[_stage_index]
        _stage_duration = _rng.randi_range(stage.duration_range.x, stage.duration_range.y)
        var mult := _rng.randf_range(stage.target_multiplier_range.x, stage.target_multiplier_range.y)
        var noise := _rng.randf_range(stage.price_noise_range.x, stage.price_noise_range.y)
        _stage_start_price = _asset.price
        _stage_target_price = _asset.price * mult * (1.0 + noise)
        _stage_start_minute = TimeManager.get_now_minutes()
