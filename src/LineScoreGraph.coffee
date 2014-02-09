_ = require 'underscore'
d3 = require 'd3'

module.exports = (mod) ->
	mod.directive 'lineScoreGraph', ->
		restrict: 'E'
		scope:
			fullwidth: '=width'
			fullheight: '=height'
			duration: '='
			scores: '='
		link: (scope, element, attrs) ->
			scope.margin = { top: 20, right: 20, bottom: 30, left: 50 }
			scope.width = scope.fullwidth - scope.margin.left - scope.margin.right
			scope.height = scope.fullheight - scope.margin.top - scope.margin.bottom

			scope.xScale = d3.scale.linear()
				.domain [0,11] # temporary until init works
				.range [0, scope.width]

			scope.yScale = d3.scale.linear()
				.domain [-200,200]
				.range [scope.height, 0]

			scope.zScale = d3.scale.category20c()

			scope.xAxis = d3.svg.axis()
				.scale scope.xScale
				.orient 'bottom'

			scope.yAxis = d3.svg.axis()
				.scale scope.yScale
				.orient 'left'

			scope.line = d3.svg.line()
				.x (d) -> scope.xScale d.month
				.y (d) -> scope.yScale d.cumulative
				.interpolate 'monotone'

			scope.svg = d3.select element[0]
				.append 'svg'
				.attr 'width', scope.fullwidth
				.attr 'height', scope.fullheight
				.append 'g'
				.attr 'transform', "translate(#{scope.margin.left},#{scope.margin.top})"

			scope.svg.append 'g'
				.attr 'class', 'x axis'
				.attr 'transform', "translate(0,#{scope.yScale 0})"
				.call scope.xAxis

			scope.svg.append 'g'
				.attr 'class', 'y axis'
				.call scope.yAxis
				.append 'text'
				.attr 'transform', 'rotate(-90)'
				.attr 'y', 12
				.text 'Score'

			scope.update = (scoreData) ->
				player = scope.svg.selectAll '.player'
					.data scoreData, (d) -> d.name

				# add new lines
				player.enter()
					.append 'g'
					.attr 'class', 'player'
					.call (s) -> scope.initPlayer s
					.style 'opacity', 0
					.transition()
					.duration scope.duration
					.style 'opacity', 1

				# update scales to match new bounds
				scope.xScale.domain [
					d3.min scoreData, (playerData) -> d3.min playerData.scores, (scoreData) -> scoreData.month
					d3.max scoreData, (playerData) -> d3.max playerData.scores, (scoreData) -> scoreData.month
				]

				scope.yScale.domain [
					d3.min scoreData, (playerData) -> d3.min playerData.scores, (scoreData) -> Math.min scoreData.cumulative, scoreData.individual
					d3.max scoreData, (playerData) -> d3.max playerData.scores, (scoreData) -> Math.max scoreData.cumulative, scoreData.individual
				]

				# rescale all new and existing lines
				player.call (s) -> scope.updatePlayer s

				# remove deleted lines
				player.exit()
					.call (s) -> scope.updatePlayer s
					.transition()
					.duration scope.duration
					.style 'opacity', 0
					.remove()

				# rescale axes
				scope.svg.select '.x.axis'
					.transition()
					.duration scope.duration
					.ease 'sin-in-out'
					.attr 'transform', "translate(0,#{scope.yScale 0})"
					.call scope.xAxis

				scope.svg.select '.y.axis'
					.transition()
					.duration scope.duration
					.ease 'sin-in-out'
					.call scope.yAxis

			scope.initPlayer = (player) ->
				player.append 'g'
					.attr 'class', 'cumulative-score'
					.append 'path'
					.style 'stroke', (d) -> scope.zScale d.name
					.attr 'd', (d) -> scope.line d.scores


				player.append 'text'
					.attr 'class', 'caption'
					.text (d) -> d.name
					.style 'fill', (d) -> scope.zScale d.name
					.attr 'x', 12
					.attr 'y', scope.height - 15

			scope.updatePlayer = (player) ->
				self = this
				barWidth = 3
				pointRadius = 4

				player.select '.cumulative-score path'
					.transition()
					.duration scope.duration
					.ease 'sin-in-out'
					.attr 'd', (d) -> scope.line d.scores

				player.each (p) ->
					cumulativeScore = d3.select(this)
						.select '.cumulative-score'
						.selectAll 'circle'
						.data (d) -> d.scores
					cumulativeScore.enter()
						.call (s) ->
							s.append 'circle'
								.attr 'r', pointRadius
								.style 'stroke', self.zScale p.name
								.transition()
								.duration scope.duration
								.ease 'sin-in-out'
								.attr 'cx', (d) -> self.xScale d.month
								.attr 'cy', (d) -> self.yScale d.cumulative

					individualScore = d3.select(this)
						.selectAll '.individual-score'
						.data (d) -> d.scores

					individualScore.enter()
						.call (s) ->
							s.append 'rect'
								.attr 'class', 'individual-score'
								.attr 'width', barWidth
								.attr 'height', (d) -> Math.abs self.yScale(0) - self.yScale(d.individual)
								.attr 'x', (d) -> self.xScale(d.month) - (barWidth / 2)
								.attr 'y', (d) -> Math.min self.yScale(0), self.yScale(d.individual) - self.yScale(self.yScale.domain()[1])
								.style 'fill', self.zScale p.name


				player.append 'path'
					.attr 'class', 'hover-target'
					.attr 'd', (d) -> scope.line d.scores
					.on 'mouseover', ->
						d3.select(this.parentNode).classed 'hover', true
						d3.select(this.parentNode.parentNode).classed 'any-hover', true
					.on 'mouseout', ->
						d3.select(this.parentNode).classed 'hover', false
						d3.select(this.parentNode.parentNode).classed 'any-hover', false

			scope.$watch 'scores', (newScores) -> scope.update newScores if newScores?