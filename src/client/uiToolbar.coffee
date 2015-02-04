$ = require 'jquery'

module.exports = class UiToolbar
	constructor: (@bundle, @selection) ->
		@_toolbarContainer = $('#toolbar')
		@_createBrushList()
		@_selectedBrush = false

		@selection.selectionChange (selectedNode) =>
			@_handleNodeSelected selectedNode

	handleMouseDown: (event) =>
		if @_selectedBrush and @selection.selectedNode?
			if @_selectedBrush.mouseDownCallback?
				@_selectedBrush.mouseDownCallback event, @selection.selectedNode

	handleMouseMove: (event) =>
		if @_selectedBrush and @selection.selectedNode?
			if @_selectedBrush.mouseMoveCallback?
				@_selectedBrush.mouseMoveCallback event, @selection.selectedNode

	handleMouseUp: (event) =>
		if @_selectedBrush and @selection.selectedNode?
			if @_selectedBrush.mouseUpCallback?
				@_selectedBrush.mouseUpCallback event, @selection.selectedNode

	hasBrushSelected: () =>
		return true if  @_selectedBrush
		return false

	_createBrushList: =>
		returnArrays = @bundle.pluginHooks.getBrushes()
		@_brushes = []

		for array in returnArrays
			for b in array
				@_brushes.push b

		for brush in @_brushes
			jqueryElement = @_createBrushUi brush
			brush.jqueryElement = jqueryElement

	_createBrushUi: (brush) =>
		html = '<div class="brushcontainer"><img src="img/' +
			brush.icon + '" width="64px" height="64px"><br><span>' +
			brush.text + '</span></div>'
		brushelement = $(html)
		brushelement.on 'click', () =>
			@_handleBrushClicked brush, brushelement
		$('#toolbar').append(brushelement)

		return brushelement

	_handleNodeSelected: (selectedNode) =>
		if selectedNode?
			if @_selectedBrush
				if @_selectedBrush.selectCallback?
					@_selectedBrush.selectCallback selectedNode

	_handleBrushClicked: (brush, jqueryElement) =>
		if @_selectedBrush
			if @_selectedBrush.deselectCallback? and @selection.selectedNode?
				@_selectedBrush.deselectCallback @selection.selectedNode

			@_selectedBrush.jqueryElement.removeClass 'brushselect'

			#edgecase: user clicked on selected brush: deselect this brush
			if @_selectedBrush == brush
				@_selectedBrush = false
				return

		@_selectedBrush = brush
		
		if @_selectedBrush.selectCallback? and @selection.selectedNode?
			@_selectedBrush.selectCallback @selection.selectedNode

		@_selectedBrush.jqueryElement.addClass 'brushselect'
