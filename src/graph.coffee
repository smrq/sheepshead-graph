margin = { top: 20, right: 20, bottom: 30, left: 50 }
width = 720 - margin.left - margin.right
height = 480 - margin.top - margin.bottom

multiExtent = (dataSet, accessor1, accessor2) -> [
	d3.min dataSet, (x) -> d3.min accessor1(x), (y) -> accessor2(y)
	d3.max dataSet, (x) -> d3.max accessor1(x), (y) -> accessor2(y)
]

x = d3.scale.linear()
	.range [0, width]

y = d3.scale.linear()
	.range [height, 0]

z = d3.scale.category20c()

xAxis = d3.svg.axis()
	.scale x
	.orient "bottom"

yAxis = d3.svg.axis()
	.scale y
	.orient "left"

line = d3.svg.line()
	.x (d) -> x d.month
	.y (d) -> y d.score
	.interpolate "basis"

svg = d3.select "body"
	.append "svg"
	.attr "width", width + margin.left + margin.right
	.attr "height", height + margin.top + margin.bottom

g = svg.append "g"
	.attr "transform", "translate(#{margin.left},#{margin.top})"

d3.json "data.json", (error, rawScoreData) ->
	scoreData = ({ name, scores: ({score, month} for score, month in scores) } for name, scores of rawScoreData.cumulative)

	x.domain multiExtent scoreData, ((d) -> d.scores), ((d) -> d.month)
	y.domain multiExtent scoreData, ((d) -> d.scores), ((d) -> d.score)

	g.append "g"
		.attr "class", "x axis"
		.attr "transform", "translate(0,#{y 0})"
		.call xAxis

	g.append "g"
		.attr "class", "y axis"
		.call yAxis
		.append "text"
		.attr "transform", "rotate(-90)"
		.attr "y", 6
		.attr "dy", ".71em"
		.style "text-anchor", "end"
		.text "Score"

	player = g.selectAll ".player"
		.data scoreData
		.enter()
		.append "g"
		.attr "class", "player"

	player.append "path"
		.attr "class", "line"
		.attr "d", (d) -> line d.scores
		.style "stroke", (d) -> z d.name

	player.append "path"
		.attr "class", "line-target"
		.attr "d", (d) -> line d.scores
		.on "mouseover", -> d3.select(this.parentNode).classed("hover", true)
		.on "mouseout", -> d3.select(this.parentNode).classed("hover", false)

	player.append "text"
		.text (d) -> d.name
		.attr "class", "caption"
		.style "fill", (d) -> z d.name
		.attr "x", 12
		.attr "y", height - 15