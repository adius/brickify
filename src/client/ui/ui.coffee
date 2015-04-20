Hotkeys = require '../hotkeys'
PointerDispatcher = require './pointerDispatcher'
WorkflowUi = require './workflowUi/workflowUi'

###
# @module ui
###

module.exports = class Ui
	constructor: (@bundle) ->
		@renderer = @bundle.renderer
		@pluginHooks = @bundle.pluginHooks
		@workflowUi = new WorkflowUi(@bundle)
		@workflowUi.init()
		@pointerDispatcher = new PointerDispatcher(@bundle)

	# Bound to updates to the window size:
	# Called whenever the window is resized.
	windowResizeHandler: (event) =>
		@renderer.windowResizeHandler()

	init: =>
		@_initListeners()
		@_initHotkeys()

	_initListeners: =>
		@pointerDispatcher.init()

		window.addEventListener(
			'resize'
			@windowResizeHandler
		)

	_initHotkeys: =>
		@hotkeys = new Hotkeys(@pluginHooks, @bundle.sceneManager)
		@hotkeys.addEvents @bundle.sceneManager.getHotkeys()

		gridHotkeys = {
			title: 'UI'
			events: [
				{
					description: 'Toggle coordinate system / lego plate'
					hotkey: 'g'
					callback: @_toggleGridVisibility
				}
				{
					description: 'Toggle stability view'
					hotkey: 's'
					callback: @_toggleStabilityView
				}
			]
		}
		@hotkeys.addEvents gridHotkeys

	_toggleGridVisibility: =>
		@bundle.getPlugin('lego-board').toggleVisibility()
		@bundle.getPlugin('coordinate-system').toggleVisibility()

	_toggleStabilityView: =>
		@workflowUi.toggleStabilityView()
