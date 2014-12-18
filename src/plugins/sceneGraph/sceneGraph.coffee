###
  # Scene Graph Plugin

  Renders interactive scene graph tree in sceneGraphContainer
###

# Should not be global but workaround for broken jqtree
global.$ = require 'jquery'
jqtree = require 'jqtree'
clone = require 'clone'
objectTree = require '../../common/objectTree'
pluginKey = 'SceneGraph'

module.exports = class SceneGraph
	constructor: () ->
		@state = null
		@uiInitialized = false
		@htmlElements = null
		@selectedNode = null
		@idCounter = 1

	init: (@bundle) ->
		return

	renderUi: (elements) =>
		@tree = $(elements.sceneGraphContainer)

		treeData = [{
			label: 'Scene',
			id: @idCounter,
			children: []
		}]
		@createTreeDataStructure(treeData[0], @state.rootNode)

		if @tree.is(':empty')
			@tree.tree {
				autoOpen: 0
				data: treeData
				dragAndDrop: false
				keyboardSupport: false
				useContextMenu: true
				onCreateLi: (node, $li) -> $li.attr('title', node.title)
			}
		@tree.tree 'loadData', treeData

		if @selectedNode
			@tree.tree 'selectNode', @selectedNode

	createTreeDataStructure: (treeNode, node) =>
		if node.pluginData[pluginKey]?
			treeNode.id = node.pluginData[pluginKey].linkedId
			# if reloading the state, get highest assigned id to prevent
			# giving objects the same id
			@idCounter = treeNode.id + 1 if treeNode.id >= @idCounter
		else
			treeNode.id = @idCounter++
			objectTree.addPluginData node, pluginKey, {linkedId: treeNode.id}

		treeNode.label = treeNode.title = node.fileName or treeNode.label or ''

		if node.children
			treeNode.children = []
			node.children.forEach (subNode, index) =>
				treeNode.children[index] = {}
				@createTreeDataStructure treeNode.children[index], subNode

	onStateUpdate: (@state, done) =>
		if @uiInitialized
			@renderUi @htmlElements
		done()

	onNodeSelect: (event) =>
		event.stopPropagation()

		if event.node
			if event.node.name == 'Scene'
				@callNodeDeselect('Scene')
				return

			# console.log "Selecting " + event.node.title
			@selectedNode = event.node

			@bundle.statesync.performStateAction (state) =>
				@getStateNodeForTreeNode event.node, state.rootNode, (stateNode) =>
					@selectedStateNode = stateNode
					@bundle.pluginUiGenerator.selectNode stateNode
		else
			# console.log "Deselecting " + @selectedNode.name
			@callNodeDeselect(@selectedNode.name)

	callNodeDeselect: (title) =>
		@bundle.pluginUiGenerator.deselectNodes()

		#definitively deselect any node
		if @tree.tree 'getSelectedNode'
			@tree.tree 'selectNode', null

		# remove selected style from node
		if title
			$(".jqtree_common [title='" + title + "']").removeClass 'jqtree-selected'

		@selectedNode = null
		@selectedStateNode = null

	bindEvents: () ->
		$treeContainer = $(@htmlElements.sceneGraphContainer)
		$treeContainer.bind 'tree.select', @onNodeSelect
		$(document).keydown (event) =>
			if event.keyCode == 46 #Delete
				@deleteObject()

	getStateNodeForTreeNode: (treeNode, stateRootNode, callback) ->
		objectTree.forAllSubnodes stateRootNode, (node) ->
			if node.pluginData[pluginKey]?
				if node.pluginData[pluginKey].linkedId == treeNode.id
					callback node

	deleteObject: () ->
		return if @bootboxOpen
		@bootboxOpen = true
		if not @selectedNode or @selectedNode.name == 'Scene'
			return

		question = "Do you really want to delete #{@selectedNode.name}?"
		bootbox.confirm question, (result) =>
			@bootboxOpen = false
			if result
				delNode = (state) =>
						objectTree.removeNode state.rootNode, @selectedStateNode
						@selectedNode = null
						@selectedStateNode = null
						@callNodeDeselect()

				@bundle.statesync.performStateAction delNode, true

	initUi: (elements) =>
		@htmlElements = elements
		@bindEvents()
		@uiInitialized = true
		if @state
			@renderUi @htmlElements
