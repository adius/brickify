###
# @module pluginLoader
###

# Load the hook list and initialize the pluginHook management
path = require 'path'
THREE = require 'three'
hooks = require './pluginHooks.yaml'
PluginHooks = require '../common/pluginHooks'

module.exports = class PluginLoader
	constructor: (@bundle) ->
		@pluginHooks = new PluginHooks()
		@pluginHooks.initHooks(hooks)
		@globalConfig = @bundle.globalConfig

	initPlugin: (PluginClass, packageData) ->
		instance = new PluginClass()

		for own key,value of packageData
			instance[key] = value

		if @pluginHooks.hasHook(instance, 'init')
			instance.init @bundle

		if @pluginHooks.hasHook(instance, 'init3d')
			threeNode = new THREE.Object3D()
			threeNode.associatedPlugin = instance
			instance.init3d threeNode

		@pluginHooks.register instance

		if threeNode?
			@bundle.renderer.addToScene threeNode

		return instance

	# Since browserify.js does not support dynamic require
	# all plugins must be explicitly written down
	loadPlugins: ->
		pluginInstances = []

		if @globalConfig.plugins.dummy
			pluginInstances.push @initPlugin(
				require '../plugins/dummy'
				require '../plugins/dummy/package.json'
			)
		if @globalConfig.plugins.stlImport
			pluginInstances.push @initPlugin(
				require '../plugins/stlImport'
				require '../plugins/stlImport/package.json'
			)
		if @globalConfig.plugins.coordinateSystem
			pluginInstances.push @initPlugin(
				require '../plugins/coordinateSystem'
				require '../plugins/coordinateSystem/package.json'
			)
		if @globalConfig.plugins.legoBoard
			pluginInstances.push @initPlugin(
				require '../plugins/legoBoard'
				require '../plugins/legoBoard/package.json'
			)
		if @globalConfig.plugins.newBrickator
			pluginInstances.push @initPlugin(
				require '../plugins/newBrickator'
				require '../plugins/newBrickator/package.json'
			)
		if @globalConfig.plugins.nodeVisualizer
			pluginInstances.push @initPlugin(
				require '../plugins/nodeVisualizer'
				require '../plugins/nodeVisualizer/package.json'
			)
		if @globalConfig.plugins.fidelityControl
			pluginInstances.push @initPlugin(
				require '../plugins/fidelityControl'
				require '../plugins/fidelityControl/package.json'
			)

		return pluginInstances
