###
# @module interactionHelper
###

THREE = require 'three'

###
# Determines the intersections a ray casted by a screen space interaction hits
# @param {Object} event usually a mouse or tap or pointer event
# @param {Number} event.pageX the x coordinate on the screen
# @param {Number} event.pageY the y coordinate on the screen
# @param {Renderer} renderer the renderer that provides the camera and canvas
# @param {Array<Object>} objects the three nodes which take part in ray casting
# @return {Array<Object>} an array of intersections
# @memberOf interactionHelper
###
getIntersections = (event, renderer, objects) ->
	ray = calculateRay event, renderer

	raycaster = new THREE.Raycaster()
	raycaster.ray.set renderer.getCamera().position, ray

	return raycaster.intersectObjects objects, true
module.exports.getIntersections = getIntersections

###
# Determines the node for a screen space interaction based on the first object
# that is intersected and has a associated node.
# @param {Object} event usually a mouse or tap or pointer event
# @param {Number} event.pageX the x coordinate on the screen
# @param {Number} event.pageY the y coordinate on the screen
# @param {Renderer} renderer the renderer that provides the camera and canvas
# @param {Array<Object>} objects the three nodes which take part in ray casting
# @return {Object|undefined} the node
# @memberOf interactionHelper
###
getNode = (event, renderer, objects) =>
	# relies on the fact that solidRenderer sets an 'associatedNode' property
	# for three nodes added
	for intersection in getIntersections event, renderer, objects
		object = intersection.object

		while object?
			return object.associatedNode if object.associatedNode?
			object = object.parent

	return undefined
module.exports.getNode = getNode

###
# Determines the responsible plugin for a screen space interaction based on
# the first object that is intersected and has a associated plugin.
# @param {Object} event usually a mouse or tap or pointer event
# @param {Number} event.pageX the x coordinate on the screen
# @param {Number} event.pageY the y coordinate on the screen
# @param {Renderer} renderer the renderer that provides the camera and canvas
# @param {Array<Object>} objects the three nodes which take part in ray casting
# @return {String|undefined} the name of the plugin
# @memberOf interactionHelper
###
getResponsiblePlugin = (event, renderer, objects) ->
	for intersection in getIntersections event, renderer, objects
		object = intersection.object

		while object?
			return object.associatedPlugin if object.associatedPlugin?
			object = object.parent

	return undefined
module.exports.getResponsiblePlugin = getResponsiblePlugin

###
# Determines the position of an event on the z=0 plane
# @param {Object} event usually a mouse or tap or pointer event
# @param {Number} event.pageX the x coordinate on the screen
# @param {Number} event.pageY the y coordinate on the screen
# @param {Renderer} renderer the renderer that provides the camera and canvas
# @return {Object} a vector {x, y, z}
# @memberOf interactionHelper
###
calculatePositionOnGrid = (event, renderer) ->
	ray = calculateRay event, renderer

	# we are calculating in camera coordinate system -> y and z are rotated
	camera = renderer.getCamera()
	ray.multiplyScalar -camera.position.y / ray.y
	posInWorld = camera.position.clone().add ray

	return x: posInWorld.x, y: -posInWorld.z, z: posInWorld.y
module.exports.getGridPosition = calculatePositionOnGrid

###
# Determines the position of an event in canvas space
# @param {Object} event usually a mouse or tap or pointer event
# @param {Number} event.pageX the x coordinate on the screen
# @param {Number} event.pageY the y coordinate on the screen
# @param {Renderer} renderer the renderer that provides the camera and canvas
# @return {Object} a three vector
# @memberOf interactionHelper
###
calculatePositionInCanvasSpace = (event, renderer) ->
	canvas = renderer.getDomElement()

	return new THREE.Vector3(
		(event.pageX / canvas.width) * 2 - 1
		(-event.pageY / canvas.height) * 2 + 1
		0.5
	)
module.exports.calculatePositionInCanvasSpace = calculatePositionInCanvasSpace

###
# Determines the position of the event in camera space
# @param {Object} event usually a mouse or tap or pointer event
# @param {Number} event.pageX the x coordinate on the screen
# @param {Number} event.pageY the y coordinate on the screen
# @param {Renderer} renderer the renderer that provides the camera and canvas
# @return {Object} a three vector
# @memberOf interactionHelper
###
calculatePositionInCameraSpace = (event, renderer) ->
	positionInCanvasCS = calculatePositionInCanvasSpace event, renderer
	return positionInCanvasCS.unproject renderer.getCamera()
module.exports.calculatePositionInCameraSpace = calculatePositionInCameraSpace

###
# Determines a virtual ray that a screen space interaction casts
# @param {Object} event usually a mouse or tap or pointer event
# @param {Number} event.pageX the x coordinate on the screen
# @param {Number} event.pageY the y coordinate on the screen
# @param {Renderer} renderer the renderer that provides the camera and canvas
# @return {Object} a normalized three vector {x, y, z}
# @memberOf interactionHelper
###
calculateRay = (event, renderer) ->
	positionInCameraCS = calculatePositionInCameraSpace event, renderer
	return positionInCameraCS.sub(renderer.getCamera().position).normalize()
module.exports.calculateRay = calculateRay
