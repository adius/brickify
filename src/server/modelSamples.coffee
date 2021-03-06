fsp = require 'fs-promise'
yaml = require 'js-yaml'
log = require('winston').loggers.get 'log'

samplesDirectory = 'modelSamples/'

samples = {}

# load samples on require (read: on server startup)
do loadSamples = ->
	fsp
		.readdirSync samplesDirectory
		.filter (file) -> file.endsWith '.yaml'
		.map (file) -> yaml.load fsp.readFileSync samplesDirectory + file
		.forEach (sample) -> samples[sample.name] = sample
	log.info 'Sample models loaded'

# API

exists = (name) ->
	if samples[name]?
		return Promise.resolve name
	else
		return Promise.reject name

get = (name) ->
	if samples[name]?
		return fsp.readFile samplesDirectory + name
	else
		return Promise.reject name

getSamples = ->
	return Object.keys samples
		.map (key) -> samples[key]
		.sort (a, b) -> a.printTime - b.printTime

module.exports = {
	exists
	get
	getSamples
}
