_ = require "underscore"

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
			.y (d) => @scaleY d.cumulative
			#.interpolate "basis"

		@svg = d3.select "body"
			.append "svg"
			.attr "width", @width + @margin.left + @margin.right
			.attr "height", @height + @margin.top + @margin.bottom

		@g = @svg.append "g"
			.attr "transform", "translate(#{@margin.left},#{@margin.top})"

	update: (scoreData) ->
		self = this

		xDomain = multiExtent scoreData, ((d) -> d.scores), ((d) -> d.month)
		yDomain = multiExtent scoreData, ((d) -> d.scores), ((d) -> d.cumulative)
		zDomain = scoreData.length

		barWidth = self.width / zDomain / (xDomain[1] - xDomain[0]) / 2

		self.scaleX.domain xDomain
		self.scaleY.domain yDomain

		player = self.g.selectAll ".player"
			.data scoreData
			.enter()
			.append "g"
			.attr "class", "player"

		player.append "path"
			.attr "class", "cumulative-score"
			.style "stroke", (d) -> self.scaleZ d.name
			.attr "d", (d) -> self.line d.scores

		player.append "path"
			.attr "class", "hover-target"
			.attr "d", (d) -> self.line d.scores
			.on "mouseover", -> d3.select(this.parentNode).classed "hover", true
			.on "mouseout", -> d3.select(this.parentNode).classed "hover", false

		player.each (p, pi) ->
			console.log p, pi
			d3.select(this)
				.selectAll ".individual-score"
				.data (d) -> d.scores
				.enter()
				.append "rect"
				.attr "class", "individual-score"
				.attr "width", barWidth
				.attr "height", (d) -> Math.abs (self.scaleY 0) - (self.scaleY d.individual)
				.attr "y", (d) -> Math.min self.scaleY(0), self.scaleY(d.individual) - self.scaleY(yDomain[1])
				.attr "x", (d) -> self.scaleX(d.month) + (barWidth * pi)
				.style "fill", self.scaleZ p.name
				.on "mouseover", -> d3.select(p).classed "hover", true
				.on "mouseout", -> d3.select(p).classed "hover", false

		player.append "text"
			.text (d) -> d.name
			.attr "class", "caption"
			.style "fill", (d) -> self.scaleZ d.name
			.attr "x", 12
			.attr "y", self.height - 15

		self.g.append "g"
			.attr "class", "x axis"
			.attr "transform", "translate(0,#{self.scaleY 0})"
			.call self.xAxis

		self.g.append "g"
			.attr "class", "y axis"
			.call self.yAxis
			.append "text"
			.attr "transform", "rotate(-90)"
			.attr "y", 6
			.attr "dy", ".71em"
			.style "text-anchor", "end"
			.text "Score"