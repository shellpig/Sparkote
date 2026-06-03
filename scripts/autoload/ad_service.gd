extends Node

signal rewarded_ad_succeeded
signal rewarded_ad_failed(reason: String)

var force_fail: bool = false

# Constant ad unit ID stub
const REWARDED_AD_UNIT_ID: String = "ca-app-pub-3940256099942544/5224354917"

func request_rewarded() -> void:
	# Simulate network delay or run in next frame
	var callable = func():
		if force_fail:
			rewarded_ad_failed.emit("debug_forced_failure")
		else:
			rewarded_ad_succeeded.emit()
	get_tree().process_frame.connect(callable, CONNECT_ONE_SHOT)
