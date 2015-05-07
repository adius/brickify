$ = require 'jquery'
modelCache = require '../../modelLoading/modelCache'
saveAs = require 'filesaver.js'

module.exports = class DownloadProvider
	constructor: (@bundle) ->
		return

	init: (jqueryString, @exportUi, @sceneManager) =>
		@jqueryObject = $(jqueryString)

		@jqueryObject.on 'click', =>
			selNode = @sceneManager.selectedNode
			if selNode?
				@_createDownload 'stl', selNode

	_createDownload: (fileType, selectedNode) =>
		downloadOptions = {
			fileType: fileType
			studRadius: @exportUi.studRadius
			holeRadius: @exportUi.holeRadius
		}

		promisesArray = @bundle.pluginHooks.getDownload selectedNode, downloadOptions

		Promise.all(promisesArray).then (resultsArray) ->
			for result in resultsArray
				if Array.isArray result
					for subResult in result
						if subResult.fileName.length > 0
							saveAs subResult.data, subResult.fileName
				else if result.fileName.length > 0
					saveAs result.data, result.fileName
