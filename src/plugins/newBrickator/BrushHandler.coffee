class BrushHandler
	constructor: ( @bundle, @newBrickator ) ->
		@highlightMaterial = new THREE.MeshLambertMaterial({
			color: 0x00ff00
		})

	getBrushes: () =>
		return [{
			containerId: '#legoBrush'
			selectCallback: @_legoSelect
			mouseDownCallback: @_legoMouseDown
			mouseMoveCallback: @_legoMouseMove
			mouseHoverCallback: @_legoMouseHover
			mouseUpCallback: @_legoMouseUp
			cancelCallback: @_legoCancel
		},{
			containerId: '#printBrush'
			selectCallback: @_printSelect
			mouseDownCallback: @_printMouseDown
			mouseMoveCallback: @_printMouseMove
			mouseHoverCallback: @_printMouseHover
			mouseUpCallback: @_printMouseUp
			cancelCallback: @_printCancel
		}]

	_checkAndPrepare: (selectedNode) =>
		# ignore if we are currently in build mode
		if @newBrickator.buildModeEnabled
			return

		return @newBrickator._getCachedData(selectedNode)

	_legoSelect: (selectedNode) =>
		@_checkAndPrepare selectedNode
		.then (cachedData) =>
			cachedData.visualization.showVoxels()
			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.setPossibleLegoBoxVisibility true
			@_setModelShadowVisiblity selectedNode, false

	_printSelect: (selectedNode) =>
		@_checkAndPrepare selectedNode
		.then (cachedData) =>
			cachedData.visualization.showVoxels()
			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.setPossibleLegoBoxVisibility false
			@_setModelShadowVisiblity selectedNode, true

	_legoMouseDown: (event, selectedNode) =>
		@_checkAndPrepare selectedNode
		.then (cachedData) =>
			voxel = cachedData.visualization.makeVoxelLego event, selectedNode
			if voxel?
				cachedData.csgNeedsRecalculation = true

	_legoMouseMove: (event, selectedNode) =>
		@_checkAndPrepare selectedNode
		.then (cachedData) =>
			voxel = cachedData.visualization.makeVoxelLego event, selectedNode
			if voxel?
				cachedData.csgNeedsRecalculation = true

	_legoMouseUp: (event, selectedNode) =>
		@_checkAndPrepare selectedNode
		.then (cachedData) =>
			touchedVoxels = cachedData.visualization.updateModifiedVoxels()
			console.log "Will re-layout #{touchedVoxels.length} voxel"
			@newBrickator.relayoutModifiedParts cachedData, touchedVoxels, true

			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.updateBricks cachedData.brickGraph.bricks

	_legoMouseHover: (event, selectedNode) =>
		@_checkAndPrepare selectedNode
		.then (cachedData) =>
			cachedData.visualization.highlightVoxel event, selectedNode, false

	_legoCancel: (event, selectedNode) =>
		@_checkAndPrepare selectedNode
		.then (cachedData) =>
			cachedData.visualization.resetTouchedVoxelsTo3dPrinted()
			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.updateBricks cachedData.brickGraph.bricks

	_printMouseDown: (event, selectedNode) =>
		@_checkAndPrepare selectedNode
		.then (cachedData) =>
			voxel = cachedData.visualization.makeVoxel3dPrinted event, selectedNode
			if voxel?
				cachedData.csgNeedsRecalculation = true

	_printMouseMove: (event, selectedNode) =>
		@_checkAndPrepare selectedNode
		.then (cachedData) =>
			voxel = cachedData.visualization.makeVoxel3dPrinted event, selectedNode
			if voxel?
				cachedData.csgNeedsRecalculation = true

	_printMouseUp: (event, selectedNode) =>
		@_checkAndPrepare selectedNode
		.then (cachedData) =>
			touchedVoxels = cachedData.visualization.updateModifiedVoxels()
			console.log "Will re-layout #{touchedVoxels.length} voxel"
			@newBrickator.relayoutModifiedParts cachedData, touchedVoxels

			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.updateBricks cachedData.brickGraph.bricks

	_printMouseHover: (event, selectedNode) =>
		@_checkAndPrepare selectedNode
		.then (cachedData) =>
			cachedData.visualization.highlightVoxel event, selectedNode, true

	_printCancel: (event, selectedNode) =>
		@_checkAndPrepare selectedNode
		.then (cachedData) =>
			cachedData.visualization.resetTouchedVoxelsToLego()
			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.updateBricks cachedData.brickGraph.bricks

	afterPipelineUpdate: (selectedNode, cachedData) =>
		cachedData.visualization.updateVoxelVisualization()
		cachedData.visualization.showVoxels()

	_setModelShadowVisiblity: (selectedNode, visible) =>
		if not @solidRenderer?
			@solidRenderer = @bundle.getPlugin('solid-renderer')
		if @solidRenderer?
			@solidRenderer.setShadowVisibility selectedNode, visible

module.exports = BrushHandler
