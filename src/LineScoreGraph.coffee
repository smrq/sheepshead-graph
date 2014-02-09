_ = require "underscore"

module.exports = class LineScoreGraph
	constructor: ({container, width, height, @duration}) ->
		@margin = { top: 20, right: 20, bottom: 30, left: 50 }
		@width = width - @margin.left - @margin.right
		@height = height - @margin.top - @margin.bottom

		@xScale = d3.scale.linear()
			.domain [0,11] # temporary until init works
			.range [0, @width]

		@yScale = d3.scale.linear()
			.domain [-200,200]
			.range [@height, 0]

		@zScale = d3.scale.category20c()

		@xAxis = d3.svg.axis()
			.scale @xScale
			.orient "bottom"

		@yAxis = d3.svg.axis()
			.scale @yScale
			.orient "left"

		@line = d3.svg.line()
			.x (d) => @xScale d.month
			.y (d) => @yScale d.cumulative
			.interpolate "monotone"

		@svg = d3.select container
			.append "svg"
			.attr "width", width
			.attr "height", height
			.append "g"
			.attr "transform", "translate(#{@margin.left},#{@margin.top})"

		@initAxes()

	update: (scoreData) ->
		player = @svg.selectAll ".player"
			.data scoreData, (d) -> d.name

		# add new lines
		player.enter()
			.append "g"
			.attr "class", "player"
			.call (s) => @initPlayer s
			.style "opacity", 0
			.transition()
			.duration @duration
			.style "opacity", 1

		# update scales to match new bounds
		@xScale.domain [
			d3.min scoreData, (playerData) -> d3.min playerData.scores, (scoreData) -> scoreData.month
			d3.max scoreData, (playerData) -> d3.max playerData.scores, (scoreData) -> scoreData.month
		]

		@yScale.domain [
			d3.min scoreData, (playerData) -> d3.min playerData.scores, (scoreData) -> Math.min scoreData.cumulative, scoreData.individual
			d3.max scoreData, (playerData) -> d3.max playerData.scores, (scoreData) -> Math.max scoreData.cumulative, scoreData.individual
		]

		# rescale all new and existing lines
		player.call (s) => @updatePlayer s

		# remove deleted lines
		player.exit()
			.call (s) => @updatePlayer s
			.transition()
			.duration @duration
			.style "opacity", 0
			.remove()

		# rescale axes
		@svg.select ".x.axis"
			.transition()
			.duration @duration
			.ease "sin-in-out"
			.attr "transform", "translate(0,#{@yScale 0})"
			.call @xAxis

		@svg.select ".y.axis"
			.transition()
			.duration @duration
			.ease "sin-in-out"
			.call @yAxis

	initPlayer: (player) ->
		player.append "g"
			.attr "class", "cumulative-score"
			.append "path"
			.style "stroke", (d) => @zScale d.name
			.attr "d", (d) => @line d.scores


		player.append "text"
			.attr "class", "caption"
			.text (d) -> d.name
			.style "fill", (d) => @zScale d.name
			.attr "x", 12
			.attr "y", @height - 15

	updatePlayer: (player) ->
		self = this
		barWidth = 3
		pointRadius = 5

		player.select ".cumulative-score path"
			.transition()
			.duration @duration
			.ease "sin-in-out"
			.attr "d", (d) => @line d.scores

		player.each (p) ->
			cumulativeScore = d3.select(this)
				.select ".cumulative-score"
				.selectAll "circle"
				.data (d) -> d.scores
			cumulativeScore.enter()
				.call (s) ->
					s.append "circle"
						.attr "r", pointRadius
						.style "stroke", self.zScale p.name
						.transition()
						.duration @duration
						.ease "sin-in-out"
						.attr "cx", (d) -> self.xScale d.month
						.attr "cy", (d) -> self.yScale d.cumulative

			individualScore = d3.select(this)
				.selectAll ".individual-score"
				.data (d) -> d.scores

			individualScore.enter()
				.call (s) ->
					s.append "rect"
						.attr "class", "individual-score"
						.attr "width", barWidth
						.attr "height", (d) -> Math.abs self.yScale(0) - self.yScale(d.individual)
						.attr "x", (d) -> self.xScale(d.month) - (barWidth / 2)
						.attr "y", (d) -> Math.min self.yScale(0), self.yScale(d.individual) - self.yScale(self.yScale.domain()[1])
						.style "fill", self.zScale p.name


		player.append "path"
			.attr "class", "hover-target"
			.attr "d", (d) => @line d.scores
			.on "mouseover", ->
				d3.select(this.parentNode).classed "hover", true
				d3.select(this.parentNode.parentNode).classed "any-hover", true
			.on "mouseout", ->
				d3.select(this.parentNode).classed "hover", false
				d3.select(this.parentNode.parentNode).classed "any-hover", false

	initAxes: ->
		@svg.append "g"
			.attr "class", "x axis"
			.attr "transform", "translate(0,#{@yScale 0})"
			.call @xAxis

		@svg.append "g"
			.attr "class", "y axis"
			.call @yAxis
			.append "text"
			.attr "transform", "rotate(-90)"
			.attr "y", 12
			.text "Score"