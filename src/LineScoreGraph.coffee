multiExtent = (dataSet, accessor1, accessor2) -> [
	d3.min dataSet, (x) -> d3.min accessor1(x), (y) -> accessor2(y)
	d3.max dataSet, (x) -> d3.max accessor1(x), (y) -> accessor2(y)
]

module.exports = class LineScoreGraph
	constructor: ({width, height}) ->
		@margin = { top: 20, right: 20, bottom: 30, left: 50 }
		@width = width - @margin.left - @margin.right
		@height = height - @margin.top - @margin.bottom

		@scaleX = d3.scale.linear()
			.range [0, @width]

		@scaleY = d3.scale.linear()
			.range [@height, 0]

		@scaleZ = d3.scale.category20c()

		@xAxis = d3.svg.axis()
			.scale @scaleX
			.orient "bottom"

		@yAxis = d3.svg.axis()
			.scale @scaleY
			.orient "left"

		@line = d3.svg.line()
			.x (d) => @scaleX d.month
			.y (d) => @scaleY d.score
			.interpolate "basis"

		@svg = d3.select "body"
			.append "svg"
			.attr "width", @width + @margin.left + @margin.right
			.attr "height", @height + @margin.top + @margin.bottom

		@g = @svg.append "g"
			.attr "transform", "translate(#{@margin.left},#{@margin.top})"

	update: (scoreData) ->
		@scaleX.domain multiExtent scoreData, ((d) -> d.scores), ((d) -> d.month)
		@scaleY.domain multiExtent scoreData, ((d) -> d.scores), ((d) -> d.score)

		@g.append "g"
			.attr "class", "x axis"
			.attr "transform", "translate(0,#{@scaleY 0})"
			.call @xAxis

		@g.append "g"
			.attr "class", "y axis"
			.call @yAxis
			.append "text"
			.attr "transform", "rotate(-90)"
			.attr "y", 6
			.attr "dy", ".71em"
			.style "text-anchor", "end"
			.text "Score"

		player = @g.selectAll ".player"
			.data scoreData
			.enter()
			.append "g"
			.attr "class", "player"

		player.append "path"
			.attr "class", "line"
			.style "stroke", (d) => @scaleZ d.name
			.transition()
			.duration(750)
			.attr "d", (d) => @line d.scores

		player.append "path"
			.attr "class", "line-target"
			.attr "d", (d) => @line d.scores
			.on "mouseover", -> d3.select(this.parentNode).classed "hover", true
			.on "mouseout", -> d3.select(this.parentNode).classed "hover", false

		player.append "text"
			.text (d) -> d.name
			.attr "class", "caption"
			.style "fill", (d) => @scaleZ d.name
			.attr "x", 12
			.attr "y", @height - 15
