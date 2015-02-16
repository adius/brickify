###
  # STL Export Plugin

  Provides functionality to save any ThreeJS geometry as a STL file.
###

$ = require 'jquery'
saveAs = require 'filesaver.js'

meshlib = require 'meshlib'
modelCache = require '../../client/modelCache'


module.exports = class StlExport

	constructor: () ->
		@$spinnerContainer = $('#spinnerContainer')

	exportStl: (encoding) =>
		@$spinnerContainer.fadeIn 'fast', () =>
			modelCache
			.request @node.meshHash
			.then (optimizedModel) =>
				meshlib
				.model optimizedModel
				.export {format: 'stl', encoding: encoding}, (error, buffer) =>
					if error then throw error
					saveAs buffer, optimizedModel.originalFileName
					@$spinnerContainer.fadeOut()

	uiEnabled: (@node) ->
		return

	getUiSchema: () =>
		type: 'object'
		actions:
			exportAsciiStl:
				title: 'Export ASCII STL'
				callback: () => @exportStl('ascii')

			exportBinaryStl:
				title: 'Export Binary STL'
				callback: () => @exportStl('binary')
