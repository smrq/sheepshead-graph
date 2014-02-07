LineScoreGraph = require "./LineScoreGraph"

graph = new LineScoreGraph
	width: 720
	height: 480

d3.json "data.json", (error, rawScoreData) ->
	scoreData = ({ name, scores: ({score, month} for score, month in scores) } for name, scores of rawScoreData.cumulative)
	graph.update scoreData