extends GutTest

func test_ad_success_path():
	AdService.force_fail = false
	AdService.request_rewarded()
	await AdService.rewarded_ad_succeeded
	assert_true(true)

func test_ad_failure_path():
	AdService.force_fail = true
	AdService.request_rewarded()
	var reason = await AdService.rewarded_ad_failed
	assert_eq(reason, "debug_forced_failure")
