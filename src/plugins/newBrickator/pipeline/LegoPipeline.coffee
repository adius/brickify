HullVoxelizer = require './HullVoxelizer'
VolumeFiller = require './VolumeFiller'
BrickLayouter = require './BrickLayouter'

module.exports = class LegoPipeline
	constructor: () ->
		@voxelizer = new HullVoxelizer()
		@volumeFiller = new VolumeFiller()
		@brickLayouter = new BrickLayouter()

		@pipelineSteps = []
		@pipelineSteps.push {
			name: 'Hull voxelizing'
			decision: (options) => return (options.voxelizing)
			worker: (lastResult, options) =>
				return @voxelizer.voxelize lastResult.optimizedModel, options
		}

		@pipelineSteps.push {
			name: 'Volume filling'
			decision: (options) => return options.voxelizing
			worker: (lastResult, options) =>
				return @volumeFiller.fillGrid lastResult.grid, options
		}

		@pipelineSteps.push {
			name: 'Layout graph initialization'
			decision: (options) => return options.layouting
			worker: (lastResult, options) =>
				return @brickLayouter.initializeBrickGraph lastResult.grid
		}

		@pipelineSteps.push {
			name: 'Layout greedy merge'
			decision: (options) => return options.layouting
			worker: (lastResult, options) =>
				return @brickLayouter.layoutByGreedyMerge lastResult.brickGraph,
				lastResult.brickGraph.bricks
		}

		@pipelineSteps.push {
			name: 'Local reLayout'
			decision: (options) => return options.reLayout
			worker: (lastResult, options) =>
				@brickLayouter.splitBricksAndRelayoutLocally lastResult.modifiedBricks,
				lastResult.brickGraph, lastResult.grid
				return lastResult
		}

		@pipelineSteps.push {
			name: 'Update Lego references in Grid'
			decision: (options) => return (options.reLayout or options.layouting)
			worker: (lastResult, options) =>
				lastResult.brickGraph.updateReferencesInGrid()
				return lastResult
		}

	run: (data, options = null, profiling = false) =>
		if profiling
			console.log "Starting Lego Pipeline
			 (voxelizing: #{options.voxelizing}, layouting: #{options.layouting},
			 onlyReLayout: #{options.reLayout})"

			profilingResults = []

		accumulatedResults = data

		for i in [0..@pipelineSteps.length - 1] by 1
			if profiling
				r = @runStepProfiled i, accumulatedResults, options
				profilingResults.push r.time
				lastResult = r.result
			else
				lastResult = @runStep i, accumulatedResults, options

			for own key of lastResult
				accumulatedResults[key] = lastResult[key]

		if profiling
			sum = 0
			for s in profilingResults
				sum += s
			console.log "Finished Lego Pipeline in #{sum}ms"

		return {
			profilingResults: profilingResults
			accumulatedResults: accumulatedResults
		}

	runStep: (i, lastResult, options) ->
		step = @pipelineSteps[i]

		if step.decision options
			return step.worker lastResult, options
		return lastResult

	runStepProfiled: (i, lastResult, options) ->
		step = @pipelineSteps[i]

		if step.decision options
			console.log "Running step #{step.name}"
			start = new Date()
			result = @runStep i, lastResult, options
			stop = new Date() - start
			console.log "Step #{step.name} finished in #{stop}ms"
		else
			console.log "(Skipping step #{step.name})"
			result = lastResult
			stop = 0

		return {
			time: stop
			result: result
		}