###
  #Fidelity Control Plugin#

  Measures the current FPS and instigates rendering fidelity changes
  accordingly via the `uglify()` and `beautify()` plugin hooks
###

$ = require 'jquery'

minimalAcceptableFps = 20
upgradeThresholdFps = 40
accumulationTime = 200
timesBelowThreshold = 5
fpsDisplayUpdateTime = 1000

###
# @class FidelityControl
###
class FidelityControl
	@fidelityLevels = [
		'DefaultLow',
		'DefaultMedium',
		'DefaultHigh',
		'PipelineLow',
		'PipelineMedium',
		'PipelineHigh',
	]

	init: (bundle) =>
		@pluginHooks = bundle.pluginHooks

		@currentFidelityLevel = 0

		@autoAdjust = true

		@accumulatedFrames = 0
		@accumulatedTime = 0

		@timesBelowMinimumFps = 0

		@_setupFpsDisplay() if process.env.NODE_ENV is 'development'

	on3dUpdate: (timestamp) =>
		if not @_lastTimestamp?
			@_lastTimestamp = timestamp
			return

		delta = timestamp - @_lastTimestamp

		@_lastTimestamp = timestamp
		@accumulatedTime += delta
		@accumulatedFrames++

		if @accumulatedTime > accumulationTime
			fps = (@accumulatedFrames / @accumulatedTime) * 1000
			@accumulatedFrames = 0
			@accumulatedTime %= accumulationTime
			@_adjustFidelity fps
			@_showFps timestamp, fps

	_adjustFidelity: (fps) =>
		return unless @autoAdjust

		if fps < minimalAcceptableFps and @currentFidelityLevel > 0
			# count how often we dropped below the desired fps
			# it has to occur at least @timesBelowThreshold times to cause a change
			@timesBelowMinimumFps++
			return if @timesBelowMinimumFps < timesBelowThreshold

			@timesBelowMinimumFps = 0
			@_decreaseFidelity()

		else if fps > upgradeThresholdFps and
		@currentFidelityLevel < FidelityControl.fidelityLevels.length - 1
			# upgrade instantly, but reset downgrade counter
			@timesBelowMinimumFps = 0

			@_increaseFidelity()

	_increaseFidelity: =>
		@currentFidelityLevel++
		@pluginHooks.setFidelity(
			@currentFidelityLevel, FidelityControl.fidelityLevels
		)

	_decreaseFidelity: =>
		@currentFidelityLevel--
		@pluginHooks.setFidelity(
			@currentFidelityLevel, FidelityControl.fidelityLevels
		)

	getHotkeys: =>
		return {
			title: 'Visual Complexity'
			events: [
				{
					description: 'Increase visual complexity (turns off automatic adjustment)'
					hotkey: 'i'
					callback: @_manualIncrease
				}
				{
					description: 'Decrease visual complexity (turns off automatic adjustment)'
					hotkey: 'd'
					callback: @_manualDecrease
				}
			]
		}

	_manualIncrease: =>
		@autoAdjust = false
		if @currentFidelityLevel < FidelityControl.fidelityLevels.length - 1
			@_increaseFidelity()

	_manualDecrease: =>
		@autoAdjust = false
		@_decreaseFidelity() if @currentFidelityLevel > 0

	_setupFpsDisplay: =>
		@lastDisplayUpdate = 0
		@$fpsDisplay = $('<div class="fps-display"></div>')
		$('body').append @$fpsDisplay

	_showFps: (timestamp, fps) =>
		if timestamp - @lastDisplayUpdate > fpsDisplayUpdateTime
			@lastDisplayUpdate = timestamp
			@$fpsDisplay.text Math.round(fps) if @$fpsDisplay?

module.exports = FidelityControl
