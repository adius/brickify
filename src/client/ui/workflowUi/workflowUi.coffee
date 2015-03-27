perfectScrollbar = require 'perfect-scrollbar'

LoadUi = require './LoadUi'
EditUi = require './EditUi'
PreviewUi = require './PreviewUi'
ExportUi = require './ExportUi'

class WorkflowUi
	constructor: (@bundle) ->
		@workflow =
			load: new LoadUi @
			edit: new EditUi @
			preview: new PreviewUi @
			export: new ExportUi @

		@enableOnly @workflow.load

	# Called by sceneManager when a node is added
	onNodeAdd: (node) =>
		@_enable ['load', 'edit', 'preview', 'export']

	# Called by sceneManager when a node is removed
	onNodeRemove: (node) =>
		@workflow.preview.quit()
		@bundle.sceneManager.scene.then (scene) =>
			@enableOnly @workflow.load if scene.nodes.length == 0

	onNodeSelect: (node) =>
		@workflow.edit.onNodeSelect node

	onNodeDeselect: (node) =>
		@workflow.edit.onNodeDeselect node

	enableOnly: (groupUi) =>
		for step, ui of @workflow
			ui.setEnabled ui is groupUi

	enableAll: =>
		@_enable Object.keys @workflow

	_enable: (groupsList) =>
		for step, ui of @workflow
			ui.setEnabled step in groupsList

	init: =>
		@_initNotImplementedMessages()
		@_initScrollbar()

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
		@workflow.preview.toggleStabilityView()

module.exports = WorkflowUi
