###
# This module estimates the printing time for a THREE.Geometry.
# @module printingTimeEstimator
###

forAllFaces = (threeGeometry, visitor) ->
	faces = threeGeometry.faces
	vertices = threeGeometry.vertices

	for face in faces
		a = vertices[face.a]
		b = vertices[face.b]
		c = vertices[face.c]
		visitor a, b, c

###
# # calculates the volume of threeGeometry
# see http://stackoverflow.com/questions/1410525
# @param {THREE.Geometry} threeGeometry an instance of three geometry
# @return {Number} volume in cm^3
###
getVolume = (threeGeometry) ->
	volume = 0
	forAllFaces threeGeometry, (a, b, c) ->
		volume += (a.x * b.y * c.z) + (a.y * b.z * c.x) + (a.z * b.x * c.y) - \
			(a.x * b.z * c.y) - (a.y * b.x * c.z) - (a.z * b.y * c.x)
	return volume / 6 / 1000


###
# calculates the surface area of threeGeometry
# @param {THREE.Geometry} threeGeometry an instance of three geometry
# @return {Number} surface in cm^2
###
getSurface = (threeGeometry) ->
	surface = 0
	forAllFaces threeGeometry, (a, b, c) ->
		ab = new THREE.Vector3 b.x - a.x, b.y - a.y, b.z - a.z
		ac = new THREE.Vector3 c.x - a.x, c.y - a.y, c.z - a.z
		surface += ab.cross(ac).length()
	return surface / 2 / 100

###
# calculates the height of threeGeometry
# @param {THREE.Geometry} threeGeometry an instance of three geometry
# @return {Number} height in cm
###
getHeight = (threeGeometry) ->
	vertices = threeGeometry.vertices
	return 0 if vertices.length is 0

	minZ = vertices[0].z
	maxZ = vertices[0].z

	for vertex in vertices
		minZ = Math.min vertex.z, minZ
		maxZ = Math.max vertex.z, maxZ

	height = maxZ - minZ
	return height / 10

###
# time approximation taken from MakerBot Desktop software configured for
# Replicator 5th Generation
# @param {THREE.Geometry} threeGeometry an instance of three geometry
# @return {Number} approximate printing time in minutes
###
getEstimate = (height, surface, volume) ->
	return 0 if volume is 0
	return 2 + 2 * height + 0.3 * surface + 2.5 * volume

module.exports.getPrintingTimeEstimate = (geometries) ->
	time = 0
	for geometry in geometries
		height = getHeight geometry
		surface = getSurface geometry
		volume = getVolume geometry

		time += getEstimate height, surface, volume

	return time

module.exports.getPrintingTimeEstimateForVoxels = (voxels, gridSpacing) ->
	return 0 if voxels.length is 0

	maxZ = voxels[0].position.z
	minZ = maxZ
	for voxel in voxels
		z = voxel.position.z
		maxZ = Math.max z, maxZ
		minZ = Math.min z, minZ

	height = (maxZ - minZ + 1) * gridSpacing.z / 10

	voxelSurface = gridSpacing.x * gridSpacing.z
	voxelSurface += gridSpacing.x * gridSpacing.y
	voxelSurface += gridSpacing.y * gridSpacing.z
	# voxelSurface *= 2
	voxelSurface /= 100
	surface = voxelSurface * voxels.length # / 2
	# to account for adjacent voxels
	surface /= 2

	voxelVolume = gridSpacing.x * gridSpacing.y * gridSpacing.z
	voxelVolume /= 1000
	volume = voxelVolume * voxels.length
	# not all voxels are completely filled
	volume /= 3

	return getEstimate height, surface, volume
