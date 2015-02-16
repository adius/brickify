THREE = require 'three'

module.exports = class Grid
	constructor: (@spacing = {x: 8, y: 8, z: 3.2}) ->
		@origin = {x: 0, y: 0, z: 0}
		@numVoxelsX = 0
		@numVoxelsY = 0
		@numVoxelsZ = 0
		@zLayers = []

	setUpForModel: (optimizedModel, options) =>
		@modelTransform = options.modelTransform

		bb = optimizedModel.boundingBox()

		# if the object is moved in the scene (not in the origin),
		# think about that while building the grid
		if @modelTransform
			bbMinWorld = new THREE.Vector3()
			bbMinWorld.set bb.min.x, bb.min.y, bb.min.z
			bbMinWorld.applyProjection(@modelTransform)

			bbMaxWorld = new THREE.Vector3()
			bbMaxWorld.set bb.max.x, bb.max.y, bb.max.z
			bbMaxWorld.applyProjection(@modelTransform)
		else
			bbMinWorld = bb.min
			bbMaxWorld = bb.max

		# 1.) Align bb minimum to next voxel position
		# 2.) spacing / 2 is subtracted to make the grid be aligned to the
		# voxel center
		# 3.) minimum z is to assure that grid is never below z=0
		calculatedZ = Math.floor(bbMinWorld.z / @spacing.z) * @spacing.z
		calculatedZ -= @spacing.z / 2
		minimumZ = @spacing.z / 2

		@origin = {
			x: Math.floor(bbMinWorld.x / @spacing.x) * @spacing.x - (@spacing.x / 2)
			y: Math.floor(bbMinWorld.y / @spacing.y) * @spacing.y - (@spacing.y / 2)
			z: Math.max(calculatedZ, minimumZ)
		}

		maxVoxel = @mapWorldToGrid bbMaxWorld
		minVoxel = @mapWorldToGrid bbMinWorld

		@numVoxelsX = (maxVoxel.x - minVoxel.x) + 1
		@numVoxelsY = (maxVoxel.y - minVoxel.y) + 1
		@numVoxelsZ = (maxVoxel.z - minVoxel.z) + 1

	mapWorldToGrid: (point) =>
		# maps world coordinates to aligned grid coordinates
		# aligned grid coordinates are world units, but relative to the
		# grid origin

		return {
			x: point.x - @origin.x
			y: point.y - @origin.y
			z: point.z - @origin.z
		}

	mapModelToGrid: (point) =>
		# maps the model local coordinates to the grid coordinates by first
		# transforming it with the modelTransform to world coordinates
		# and then converting it to aligned grid coordinates

		if @modelTransform?
			v = new THREE.Vector3(point.x, point.y, point.z)
			v.applyProjection(@modelTransform)
			return @mapWorldToGrid v
		else
			# if model is placed at 0|0|0,
			# model and world coordinates are in the same system
			return @mapWorldToGrid point

	mapGridToVoxel: (point) =>
		# maps aligned grid coordinates to voxel indices
		# cut z<0 to z=0, since the grid cannot have
		# voxels in negative direction
		return {
			x: Math.round(point.x / @spacing.x)
			y: Math.round(point.y / @spacing.y)
			z: Math.max(Math.round(point.z / @spacing.z), 0)
		}

	mapVoxelToGrid: (point) =>
		# maps voxel indices to aligned grid coordinates
		return {
			x: point.x * @spacing.x
			y: point.y * @spacing.y
			z: point.z * @spacing.z
		}

	mapVoxelToWorld: (point) =>
		# maps voxel indices to world coordinates
		relative = @mapVoxelToGrid point
		return {
			x: relative.x + @origin.x
			y: relative.y + @origin.y
			z: relative.z + @origin.z
		}

	setVoxel: (voxel, data = true) =>
		# sets the voxel with the given indices to true
		# the voxel may also contain data.
		if not @zLayers[voxel.z]
			@zLayers[voxel.z] = []
		if not @zLayers[voxel.z][voxel.x]
			@zLayers[voxel.z][voxel.x] = []

		if not @zLayers[voxel.z][voxel.x][voxel.y]?
			voxData = {dataEntrys: [data], enabled: true, brick: false}
			@zLayers[voxel.z][voxel.x][voxel.y] = voxData
		else
			#if the voxel already exists, push new data to existing array
			@zLayers[voxel.z][voxel.x][voxel.y].dataEntrys.push data

	forEachVoxel: (callback) =>
		for z in [0..@numVoxelsZ - 1] by 1
			for y in [0..@numVoxelsY - 1] by 1
				for x in [0..@numVoxelsX - 1] by 1
					if @zLayers[z]?[x]?[y]?
						vox = @zLayers[z][x][y]
						callback vox, x, y, z

