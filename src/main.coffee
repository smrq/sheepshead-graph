_ = require "underscore"
LineScoreGraph = require "./LineScoreGraph"

graph = new LineScoreGraph
	width: 1024
	height: 600

d3.json "data.json", (error, rawScoreData) ->
	scoreData = for name, cumulativeScores of rawScoreData.cumulative
		individualScores = rawScoreData.individual[name]

		name: name
		scores: for [cumulative, individual], month in _.zip cumulativeScores, individualScores
			{ cumulative, individual, month }

	graph.update scoreData