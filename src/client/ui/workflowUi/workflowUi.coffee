DownloadProvider = require './downloadProvider'
BrushSelector = require './brushSelector'
perfectScrollbar = require 'perfect-scrollbar'

LoadUi = require './LoadUi'
EditUi = require './EditUi'
PreviewUi = require './PreviewUi'
ExportUi = require './ExportUi'

module.exports = class WorkflowUi
	constructor: (@bundle) ->
		@downloadProvider = new DownloadProvider(@bundle)
		@brushSelector = new BrushSelector(@bundle)
		@numObjects = 0

		@workflow =
			load: new LoadUi()
			edit: new EditUi()
			preview: new PreviewUi()
			export: new ExportUi()

		@enableOnly @workflow.load

	# Called by sceneManager when a node is added
	onNodeAdd: (node) =>
		@numObjects++

		# enable rest of UI
		@_enable ['load', 'edit', 'preview', 'export']

	# Called by sceneManager when a node is removed
	onNodeRemove: (node) =>
		if @stabilityCheckModeEnabled
			@stabilityCheckModeEnabled = false
			@_enableNonStabilityUi()
			@_setStabilityCheckButtonActive false

		@numObjects--

		if @numObjects == 0
			# disable rest of UI
			@_enable ['load']

	onNodeSelect: (node) =>
		@brushSelector.onNodeSelect node

	onNodeDeselect: (node) =>
		@brushSelector.onNodeDeselect node

	enableOnly: (groupUi) =>
		for step, ui of @workflow
			ui.setEnabled ui is groupUi

	enableAll: =>
		@_enable Object.keys @workflow

	_enable: (groupsList) =>
		for step, ui of @workflow
			ui.setEnabled step in groupsList

	init: =>
		@sceneManager = @bundle.sceneManager
		@downloadProvider.init('#downloadButton', @sceneManager)
		@brushSelector.init '#brushContainer'
		@nodeVisualizer = @bundle.getPlugin 'nodeVisualizer'

		@_initStabilityCheck()
		@_initBuildButton()
		@_initNotImplementedMessages()
		@_initScrollbar()

	_initStabilityCheck: =>
		@stabilityCheckButton = $('#stabilityCheckButton')
		@stabilityCheckModeEnabled = false

		@stabilityCheckButton.on 'click', @toggleStabilityView

	_applyStabilityViewMode: =>
		#disable other UI
		if @stabilityCheckModeEnabled
			@_disableNonStabilityUi()
		else
			@_enableNonStabilityUi()

		@_setStabilityCheckButtonActive @stabilityCheckModeEnabled
		@nodeVisualizer._setStabilityView(
			@sceneManager.selectedNode, @stabilityCheckModeEnabled
		)

	_initBuildButton: =>
		@buildButton = $('#buildButton')
		@buildModeEnabled = false

		@buildContainer = $('#buildContainer')
		@buildContainer.hide()
		@buildContainer.removeClass 'hidden'

		@buildLayerUi = {
			slider: $('#buildSlider')
			decrement: $('#buildDecrement')
			increment: $('#buildIncrement')
			curLayer: $('#currentBuildLayer')
			maxLayer: $('#maxBuildLayer')
			}

		@buildLayerUi.slider.on 'input', =>
			selectedNode = @bundle.sceneManager.selectedNode
			v = @buildLayerUi.slider.val()
			@_updateBuildLayer(selectedNode)

		@buildLayerUi.increment.on 'click', =>
			selectedNode = @bundle.sceneManager.selectedNode
			v = @buildLayerUi.slider.val()
			v++
			@buildLayerUi.slider.val(v)
			@_updateBuildLayer(selectedNode)

		@buildLayerUi.decrement.on 'click', =>
			selectedNode = @bundle.sceneManager.selectedNode
			v = @buildLayerUi.slider.val()
			v--
			@buildLayerUi.slider.val(v)
			@_updateBuildLayer(selectedNode)

		@buildButton.click =>
			selectedNode = @bundle.sceneManager.selectedNode

			if @buildModeEnabled
				@buildContainer.slideUp()
				@buildButton.removeClass('active')
				@_disableBuildMode selectedNode
			else
				@buildContainer.slideDown()
				@buildButton.addClass('active')
				@_enableBuildMode selectedNode

			@buildModeEnabled = !@buildModeEnabled

	_enableBuildMode: (selectedNode) =>
		@nodeVisualizer.enableBuildMode(selectedNode).then (numZLayers) =>
			# disable other UI
			@_disableNonBuildUi()

			# apply grid size to layer view
			@buildLayerUi.slider.attr('min', 0)
			@buildLayerUi.slider.attr('max', numZLayers)
			@buildLayerUi.maxLayer.html(numZLayers)

			@buildLayerUi.slider.val(1)
			@_updateBuildLayer selectedNode

	_updateBuildLayer: (selectedNode) =>
		layer = @buildLayerUi.slider.val()
		@buildLayerUi.curLayer.html(Number(layer))

		@nodeVisualizer.showBuildLayer(selectedNode, layer)

	_disableBuildMode: (selectedNode) =>
		@nodeVisualizer.disableBuildMode(selectedNode).then =>
			# enable other ui
			@_enableNonBuildUi()


	_disableNonBuildUi: =>
		@_enable ['preview']
		@stabilityCheckButton.addClass 'disabled'

	_enableNonBuildUi: =>
		@_enable ['load', 'edit', 'preview', 'export']
		@stabilityCheckButton.removeClass 'disabled'

	_disableNonStabilityUi: =>
		@_enable ['preview']
		@buildButton.addClass 'disabled'

	_enableNonStabilityUi: =>
		@_enable ['load', 'edit', 'preview', 'export']
		@buildButton.removeClass 'disabled'

	_setStabilityCheckButtonActive: (active) =>
		@stabilityCheckButton.toggleClass 'active', active

	_initNotImplementedMessages: =>
		alertCallback = ->
			bootbox.alert({
					title: 'Not implemented yet'
					message: 'We are sorry, but this feature is not implemented yet.
					 Please check back later.'
			})

		$('#everythingPrinted').click alertCallback
		$('#everythingLego').click alertCallback
		$('#downloadPdfButton').click alertCallback
		$('#shareButton').click alertCallback

	_initScrollbar: =>
		sidebar = document.getElementById 'leftSidebar'
		perfectScrollbar.initialize sidebar
		window.addEventListener 'resize', -> perfectScrollbar.update sidebar

	toggleStabilityView: =>
		@stabilityCheckModeEnabled = !@stabilityCheckModeEnabled
		@_applyStabilityViewMode()
