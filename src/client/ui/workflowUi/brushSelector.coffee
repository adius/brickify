###
# @class BrushSelector
###
class BrushSelector
	constructor: (@bundle) ->
		@selectedNode = null

	init: (jQueryBrushContainerSelector) =>
		@_selectedBrush = null
		@_bigBrushSelected = false

		@brushContainer = $(jQueryBrushContainerSelector)

		@_brushList ?= []

		for brush in @_brushList
			htmlContainer = @brushContainer.find brush.containerId
			brush.jqueryObject = htmlContainer
			@_bindBrushEvent brush

	# binds the given brushes to the UI
	setBrushes: (@_brushList) => return

	onNodeSelect: (node) =>
		@selectedNode = node

		if not @_selectedBrush and @_brushList.length > 0
			@_bigBrushSelected = false
			@_brushSelect @_brushList[@_brushList.length - 1]

	onNodeDeselect: (node) =>
		@_deselectBrush node
		@selectedNode = null

	_bindBrushEvent: (brush) ->
		brush.jqueryObject.on 'click', (event) =>
			@_bigBrushSelected = event.shiftKey
			@_brushSelect brush

	_brushSelect: (brush) =>
		# deselect currently selected brush
		@_deselectBrush @selectedNode

		#select new brush
		@_selectedBrush = brush
		brush.jqueryObject.addClass 'active'
		brush.selectCallback? @selectedNode, @_bigBrushSelected

	_deselectBrush: (node) =>
		if @_selectedBrush?
			@_selectedBrush.deselectCallback? node
			@_selectedBrush.jqueryObject.removeClass 'active'
			@_selectedBrush = null

	getSelectedBrush: =>
		return @_selectedBrush

	toggleBrush: =>
		for brush in @_brushList
			if brush isnt @_selectedBrush
				@_brushSelect brush
				return true
		return false

module.exports = BrushSelector
