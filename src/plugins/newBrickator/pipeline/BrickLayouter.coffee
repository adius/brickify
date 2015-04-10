Brick = require './Brick'
BrickGraph = require './BrickGraph'
arrayHelper = require './arrayHelper'

###
# @class BrickLayouter
###

class BrickLayouter
	constructor: (pseudoRandom = false) ->
		if pseudoRandom
			@seed = 42
			@_random = @_pseudoRandom
		return

	initializeBrickGraph: (grid) ->
		return brickGraph: new BrickGraph(grid)

	# main while loop condition:
	# any brick can still merge --> use heuristic:
	# keep a counter, break if last number of unsuccessful tries > (some number
	# or some % of total bricks in object)
	layoutByGreedyMerge: (brickGraph, bricksToLayout) =>
		numRandomChoices = 0
		numRandomChoicesWithoutMerge = 0
		numTotalInitialBricks = 0

		if not bricksToLayout?
			bricksToLayout = brickGraph.bricks

		for layer in bricksToLayout
			numTotalInitialBricks += layer.length
		maxNumRandomChoicesWithoutMerge = numTotalInitialBricks

		return unless numTotalInitialBricks > 0

		loop
			brick = @_chooseRandomBrick bricksToLayout
			if !brick?
				return {brickGraph: brickGraph}

			numRandomChoices++
			mergeableNeighbors = @_findMergeableNeighbors brick

			if !@_anyDefined(mergeableNeighbors)
				numRandomChoicesWithoutMerge++
				if numRandomChoicesWithoutMerge >= maxNumRandomChoicesWithoutMerge
					console.log " - randomChoices #{numRandomChoices}
											withoutMerge #{numRandomChoicesWithoutMerge}"
					# done with initial layout
					break
				else
					# randomly choose a new brick
					continue

			while(@_anyDefined(mergeableNeighbors))
				mergeIndex = @_chooseNeighborsToMergeWith mergeableNeighbors
				brick = @_mergeBricksAndUpdateGraphConnections brick,
					mergeableNeighbors, mergeIndex, brickGraph, bricksToLayout
				mergeableNeighbors = @_findMergeableNeighbors brick

		return {brickGraph: brickGraph}

	optimizeForStability: (bricks) =>
		for layer in bricks # access removed element?
			for brick in layer
				if brick? and brick.uniqueConnectedBricks().length is 0
					console.log brick
					if brick.uniqueNeighbors().length is 0
						0
						#arrayHelper.removeFirstOccurenceFromArray brick, bricks[brick.position.z]
					else
						console.log 'splitting brick and relayouting'
						console.log brick
						neighbors = brick.uniqueNeighbors()
						oldBricks = neighbors.concat(brick)
						@_splitBricksAndRelayout oldBricks, bricks

		#console.log @_findWeakArticulationPoints bricks

	###
	# Split up all supplied bricks into single bricks and relayout. This means
	# that all bricks will be relayouted.
	#
	# @param {Array<Brick>} oldBricks
	# @param {Array<Array<Brick>>} bricks
	###
	_splitBricksAndRelayout: (oldBricks, bricks) =>
		newBricks = @_splitBricks oldBricks, bricks
		@layoutByGreedyMerge bricks
		return

	###
	# Split up all supplied bricks into single bricks and relayout locally. This
	# means that all supplied bricks and their neighbors will be relayouted.
	#
	# @param {Array<Brick>} oldBricks
	# @param {BrickGraph} brickGraph
	###
	splitBricksAndRelayoutLocally: (oldBricks, brickGraph, grid) =>
		bricksToSplit = []

		for brick in oldBricks
			bricksToSplit = bricksToSplit.concat brick.uniqueNeighbors()
			bricksToSplit.push brick

		bricksToSplit = arrayHelper.removeDuplicates bricksToSplit

		newBricks = @_splitBricks bricksToSplit, brickGraph

		legoBricks = []
		for brick in newBricks
			p = brick.position
			if grid? and not grid.hasVoxelAt p.x, p.y, p.z
				# This brick does not belong to any voxel --> delete brick
				brickGraph.deleteBrick brick
			else if grid? and not grid.getVoxel(p.x, p.y, p.z).enabled
				# This voxel is going to be 3d printed --> delete brick
				brickGraph.deleteBrick brick
			else
				legoBricks.push brick

		# reset visible material
		for brick in legoBricks
			brick.visualizationMaterial = null

		@layoutByGreedyMerge brickGraph, [legoBricks]

		return {
			removedBricks: bricksToSplit
			newBricks: legoBricks
		}

	# splits each brick in bricks to split, updates reference in brickGraph
	_splitBricks: (bricksToSplit, brickGraph) ->
		newBricks = []

		for brick in bricksToSplit
			newBricks = newBricks.concat brick.split()
			brickGraph.deleteBrick brick

		for newBrick in newBricks
			brickGraph.bricks[newBrick.position.z].push newBrick

		return newBricks

	_anyDefined: (mergeableNeighbors) ->
		return mergeableNeighbors.some (entry) -> entry?

	# choses a random brick out of brickLayers
	_chooseRandomBrick: (brickLayers) =>
		i = 0
		brickList = brickLayers[@_random(brickLayers.length)]

		while brickList.length is 0 # if a layer has no bricks, retry
			if ++i >= brickLayers.length
				return null
			brickList = brickLayers[@_random(brickLayers.length)]

		brick = brickList[@_random(brickList.length)]
		return brick

	_random: (max) ->
		Math.floor Math.random() * max

	_pseudoRandom: (max) ->
		@seed = (1103515245 * @seed + 12345) % 2 ^ 31
		@seed % max

	# Searches for mergeable neighbours in [x-, x+, y-, y+] direction
	# and returns an array out of arrays of IDs for each direction
	_findMergeableNeighbors: (brick) =>
		mergeableNeighbors = []

		mergeableNeighbors.push @_findMergeableNeighborsInDirection(
			brick
			Brick.direction.Xm
			(obj) -> return obj.y
			(obj) -> return obj.x
		)
		mergeableNeighbors.push @_findMergeableNeighborsInDirection(
			brick
			Brick.direction.Xp
			(obj) -> return obj.y
			(obj) -> return obj.x
		)
		mergeableNeighbors.push @_findMergeableNeighborsInDirection(
			brick
			Brick.direction.Ym
			(obj) -> return obj.x
			(obj) -> return obj.y
		)
		mergeableNeighbors.push @_findMergeableNeighborsInDirection(
			brick
			Brick.direction.Yp
			(obj) -> return obj.x
			(obj) -> return obj.y
		)

		return mergeableNeighbors

	###
	# Checks if brick can merge in the direction specified.
	#
	# @param {Brick} brick the brick whose neighbors to check
	# @param {Number} dir the merge direction as specified in Brick.direction
	# @param {Function} widthFn the function to determine the brick's width
	# @param {Function} lengthFn the function to determine the brick's height
	# @return {Array<Brick>} Bricks in the merge direction if this brick can merge
	# in this dir undefined otherwise.
	# @see Brick
	###
	_findMergeableNeighborsInDirection: (brick, dir, widthFn, lengthFn) ->
		if brick.neighbors[dir].length > 0
			width = 0
			ids = []
			for neighbor in brick.neighbors[dir]
				width += widthFn neighbor.size
				if neighbor.id in ids
					console.warn 'detected duplicate neighbour'
					console.warn neighbor.id
					console.warn brick
					return
				else
					ids.push neighbor.id
			if width == widthFn(brick.size)
				minWidth = widthFn brick.position
				maxWidth = widthFn(brick.position) + widthFn(brick.size) - 1
				length = lengthFn(brick.neighbors[dir][0].size)
				for neighbor in brick.neighbors[dir]
					if widthFn(neighbor.position) < minWidth
						return
					else if widthFn(neighbor.position) +
					widthFn(neighbor.size) - 1 > maxWidth
						return
					if lengthFn(neighbor.size) != length
						return
				if Brick.isValidSize(widthFn(brick.size), lengthFn(brick.size) +
				length, brick.size.z)
					return brick.neighbors[dir]

	# Returns the index of the mergeableNeighbors sub-array,
	# where the bricks have the most connected neighbors.
	# If multiple sub-arrays have the same number of connected neigbours,
	# one is randomly chosen
	_chooseNeighborsToMergeWith: (mergeableNeighbors) =>
		numConnections = []
		maxConnections = 0

		for neighbors, i in mergeableNeighbors
			connectedBricks = []
			continue if not neighbors

			for neighbor in neighbors
				connectedBricks = connectedBricks.concat neighbor.uniqueConnectedBricks()
			connectedBricks = arrayHelper.removeDuplicates connectedBricks

			numConnections.push {
				num: connectedBricks.length
				index: i
			}
			maxConnections = Math.max maxConnections, connectedBricks.length

		largestConnections = numConnections.filter (element) ->
			return element.num == maxConnections

		randomOfLargest = largestConnections[@_random(largestConnections.length)]
		return randomOfLargest.index

	_mergeBricksAndUpdateGraphConnections: (
		brick, mergeableNeighbors, mergeIndex, brickGraph, bricksToLayout ) ->

		mergeNeighbors = mergeableNeighbors[mergeIndex]

		ps = brick.getPositionAndSizeForNewBrick mergeIndex, mergeNeighbors
		newBrick = new Brick(ps.position, ps.size)

		#save oldBricks in newBrick for debugging
		newBrick.mergedNeighbors = mergeNeighbors
		newBrick.mergedBrick = brick

		# set new brick connections & neighbors
		for neighbor in mergeNeighbors
			newBrick.getConnectionsFromMergingBrick neighbor
			newBrick.getNeighborsFromMergingBrick neighbor
		newBrick.getConnectionsFromMergingBrick brick
		newBrick.getNeighborsFromMergingBrick brick

		# delete outdated bricks from bricks array
		z = brick.position.z
		arrayHelper.removeFirstOccurenceFromArray brick, brickGraph.bricks[z]
		if bricksToLayout
			arrayHelper.removeFirstOccurenceFromArray brick, bricksToLayout[0]
		for neighbor in mergeNeighbors
			arrayHelper.removeFirstOccurenceFromArray neighbor, brickGraph.bricks[z]
			if bricksToLayout
				arrayHelper.removeFirstOccurenceFromArray neighbor, bricksToLayout[0]

		# add newBrick to bricks array
		brickGraph.bricks[z].push newBrick
		return newBrick

	_getBiconnectedComponents: (bricks) =>
		@index = 0
		biconnectedComponents = []
		stack = []
		for zLayer in bricks
			for brick in zLayer
				if brick.biconnectedComponentId == undefined
					@_findBiconnectedComponents brick, biconnectedComponents, stack
		return biconnectedComponents

	###
	# This algorithm searches for biconnected components in the subgraph that is
	# reachable from the supplied brick.
	# see http://en.algoritmy.net/article/44220/Tarjans-algorithm
	#
	# @param {Brick} brick
	# @param {Array<Array<Brick>>} biconnectedComponents
	# @param {Array<Brick>} stack
	# @param {Brick} brick
	###
	_findBiconnectedComponents: (brick, biconnectedComponents, stack) =>
		brick.biconnectedComponentId = @index
		brick.lowlink = @index
		@index++
		stack.push(brick)
		for connectedBrick in brick.uniqueConnectedBricks()
			if connectedBrick.biconnectedComponentId == undefined
				@_findBiconnectedComponents(connectedBrick, biconnectedComponents, stack)
				brick.lowlink = if brick.lowlink < connectedBrick.lowlink
				then brick.lowlink else connectedBrick.lowlink
			else if stack.indexOf(connectedBrick) > -1
				brick.lowlink = if brick.lowlink < connectedBrick.lowlink
				then brick.lowlink else connectedBrick.lowlink

		if brick.lowlink == brick.biconnectedComponentId
			otherBrick = null
			component = []
			while true
				otherBrick = stack.pop()
				component.push otherBrick
				break if otherBrick == brick
			biconnectedComponents.push component

	###
	# Find weak articulation points in the graph.
	#
	# @param {Array<Brick>} bricks All bricks in the graph
	# @return {Array<Brick>} Bricks that are weak articulation points
	###
	_findWeakArticulationPoints: (bricks) =>
		# TODO filter out trivial articulation points
		return @_getArticulationPoints bricks

	###
	# Find potentially weak points (articulation points) in the graph.
	#
	# @param {Array<Brick>} bricks All bricks in the graph
	# @return {Array<Brick>} Bricks that are articulation points
	###
	_getArticulationPoints: (bricks) =>
		@time = 0
		articulationPoints = []
		for zLayer in bricks
			for brick in zLayer
				brick.discovered = false
				brick.parent = null
				brick.discoveryTime = -1
		for zLayer in bricks
			for brick in zLayer
				if brick.discovered == undefined or !brick.discovered
					@_findArticulationPoints brick, articulationPoints
		articulationPoints

	###
	# Find potentially weak points in the subgraph that is reachable from the
	# supplied brick.
	#
	# @param {Brick} brick the start brick
	# @param {Array} articulationPoints An Array of previously found articulation
	# points. The results are appended to this array.
	###
	_findArticulationPoints: (brick, articulationPoints) =>
		brick.discoveryTime = brick.lowlink = ++@time
		brick.discovered = true
		children = 0
		for otherBrick in brick.uniqueConnectedBricks()
			if otherBrick.discovered is undefined or !otherBrick.discovered
				otherBrick.parent = brick
				children++
				@_findArticulationPoints otherBrick, articulationPoints
				brick.lowlink = Math.min brick.lowlink, otherBrick.lowlink
				if !brick.parent? and children > 1
					articulationPoints.push brick
				if brick.parent?
					if otherBrick.lowlink >= brick.discoveryTime
						articulationPoints.push brick
			else if otherBrick.parent != brick
				brick.lowlink = Math.min brick.lowlink, otherBrick.discoveryTime

module.exports = BrickLayouter
