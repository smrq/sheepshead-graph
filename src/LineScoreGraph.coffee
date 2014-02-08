_ = require "underscore"

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
			.interpolate "cardinal"

		@svg = d3.select "body"
			.append "svg"
			.attr "width", @width + @margin.left + @margin.right
			.attr "height", @height + @margin.top + @margin.bottom

		@g = @svg.append "g"
			.attr "transform", "translate(#{@margin.left},#{@margin.top})"

	drawHoverTarget: (player) ->
		player.append "path"
			.attr "class", "hover-target"
			.attr "d", (d) => @line d.scores
			.on "mouseover", ->
				d3.select(this.parentNode).classed "hover", true
				d3.select(this.parentNode.parentNode).classed "hover", true
			.on "mouseout", ->
				d3.select(this.parentNode).classed "hover", false
				d3.select(this.parentNode.parentNode).classed "hover", false

	drawIndividualScoreBars: (player) ->
		self = this
		barWidth = 3

		player.each (p) ->
			d3.select(this)
				.selectAll ".individual-score"
				.data (d) -> d.scores
				.enter()
				.append "rect"
				.attr "class", "individual-score"
				.attr "width", barWidth
				.attr "height", (d) -> Math.abs self.scaleY(0) - self.scaleY(d.individual)
				.attr "y", (d) -> Math.min self.scaleY(0), self.scaleY(d.individual) - self.scaleY(self.scaleY.domain()[1])
				.attr "x", (d) -> self.scaleX(d.month) - (barWidth / 2)
				.style "fill", self.scaleZ p.name

	drawCaption: (player) ->
		player.append "text"
			.text (d) -> d.name
			.attr "class", "caption"
			.style "fill", (d) => @scaleZ d.name
			.attr "x", 12
			.attr "y", @height - 15

	drawCumulativeScoreLine: (player) ->
		player.append "path"
			.attr "class", "cumulative-score"
			.style "stroke", (d) => @scaleZ d.name
			.attr "d", (d) => @line d.scores

	drawAxes: ->
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

	updateDomain: (scoreData) ->
		@scaleX.domain [
			d3.min scoreData, (playerData) -> d3.min playerData.scores, (scoreData) -> scoreData.month
			d3.max scoreData, (playerData) -> d3.max playerData.scores, (scoreData) -> scoreData.month
		]

		@scaleY.domain [
			d3.min scoreData, (playerData) -> d3.min playerData.scores, (scoreData) -> Math.min scoreData.cumulative, scoreData.individual
			d3.max scoreData, (playerData) -> d3.max playerData.scores, (scoreData) -> Math.max scoreData.cumulative, scoreData.individual
		]

	update: (scoreData) ->
		@updateDomain scoreData

		player = @g.selectAll ".player"
			.data scoreData
			.enter()
			.append "g"
			.attr "class", "player"

		@drawIndividualScoreBars player
		@drawCumulativeScoreLine player
		@drawCaption player
		@drawHoverTarget player
		@drawAxes()