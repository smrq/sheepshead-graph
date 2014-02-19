_ = require 'underscore'
d3 = require 'd3'

d3.selection.prototype.moveToFront = ->
	@each ->
		@parentNode.appendChild this

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

			scope.pointRadius = 4
			scope.hoverRadius = 30
			scope.barWidth = 3

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

			scope.voronoi = d3.geom.voronoi()
				.x (d) -> scope.xScale d.month
				.y (d) -> scope.yScale d.cumulative
				.clipExtent [
					[-scope.margin.left, -scope.margin.top]
					[scope.width + scope.margin.right, scope.height + scope.margin.bottom]
				]

			scope.svg = d3.select element[0]
				.append 'svg'
				.attr 'width', scope.fullwidth
				.attr 'height', scope.fullheight
				.append 'g'
				.attr 'transform', "translate(#{scope.margin.left},#{scope.margin.top})"

			scope.svgDefs = scope.svg.append 'defs'

			scope.playerGroup = scope.svg.append 'g'
				.attr 'class', 'players'
			scope.voronoiGroup = scope.svg.append 'g'
				.attr 'class', 'voronoi'

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

			scope.voronoiData = ->
				d3.nest()
					.key (d) -> scope.xScale(d.month) + ',' + scope.yScale(d.cumulative)
					.rollup (v) -> v[0]
					.entries d3.merge scope.scores.map ({name, scores}) ->
						scores.map ({cumulative, month}) ->
							{ name, cumulative, month }
					.map (d) -> d.values

			scope.voronoiMouseover = ({point}) ->
				allPlayers = scope.playerGroup.selectAll '.player'
				thisPlayer = allPlayers.filter (d) -> d.name is point.name
				otherPlayers = allPlayers.filter (d) -> d.name isnt point.name

				thisPlayer.classed 'hover', true
					.moveToFront()
				thisPlayer.selectAll '.cumulative-score circle'
					.filter (d) -> d.month is point.month
					.transition()
					.duration 100
					.attr 'r', scope.pointRadius * 2
					.style 'stroke-width', '5px'

				otherPlayers.classed 'no-hover', true

			scope.voronoiMouseout = ({point}) ->
				allPlayers = scope.playerGroup.selectAll '.player'
				thisPlayer = allPlayers.filter (d) -> d.name is point.name
				otherPlayers = allPlayers.filter (d) -> d.name isnt point.name

				thisPlayer.classed 'hover', false
				thisPlayer.selectAll '.cumulative-score circle'
					.filter (d) -> d.month is point.month
					.transition()
					.duration 100
					.attr 'r', scope.pointRadius
					.style 'stroke-width', '2.5px'

				otherPlayers.classed 'no-hover', false

			scope.update = ->
				player = scope.playerGroup.selectAll '.player'
					.data scope.scores, (d) -> d.name

				# add new lines
				player.enter().call (p) ->
					p.append 'g'
						.attr 'class', 'player'
						.call (s) -> scope.initPlayer s
						.style 'opacity', 0
						.transition()
						.duration scope.duration
						.style 'opacity', 1

				# update scales to match new bounds
				if scope.scores.length > 0
					scope.xScale.domain [
						d3.min scope.scores, (p) -> d3.min p.scores, (s) -> s.month
						d3.max scope.scores, (p) -> d3.max p.scores, (s) -> s.month
					]

					scope.yScale.domain [
						d3.min scope.scores, (p) -> d3.min p.scores, (s) -> Math.min s.cumulative, s.individual
						d3.max scope.scores, (p) -> d3.max p.scores, (s) -> Math.max s.cumulative, s.individual
					]

				# rescale all new and existing lines
				player.call (s) -> scope.updatePlayer s

				# remove deleted lines
				player.exit()
					.call (s) -> scope.updatePlayer s
					.transition()
					.duration scope.duration
					.ease 'exp-out'
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

				# voronoi hover targets
				voronoiPath = scope.voronoiGroup.selectAll 'path'
					.data scope.voronoi(scope.voronoiData()), scope.polygon
				voronoiPath.exit()
					.remove()
				voronoiPath.enter()
					.append 'path'
					.attr 'd', scope.polygon
					.attr 'clip-path', (d, i) -> 'url(#voronoi-clip-' + i + ')'
					.on 'mouseover', scope.voronoiMouseover
					.on 'mouseout', scope.voronoiMouseout
				
				voronoiClip = scope.svgDefs.selectAll '.voronoi-clip'
					.data scope.voronoi(scope.voronoiData()), scope.polygon
				voronoiClip.exit()
					.remove()
				voronoiClip.enter()
					.append 'clipPath'
					.attr 'class', 'voronoi-clip'
					.attr 'id', (d, i) -> 'voronoi-clip-' + i
					.append 'circle'
					.attr 'r', scope.hoverRadius
					.attr 'cx', (d) -> scope.xScale d.point.month
					.attr 'cy', (d) -> scope.yScale d.point.cumulative

			scope.polygon = (points) ->
				'M' + points.join('L') + 'Z'

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

				player.each (p) -> scope.intoPlayer p, this

			scope.updatePlayer = (player) ->
				player.select '.cumulative-score path'
					.transition()
					.duration scope.duration
					.ease 'sin-in-out'
					.attr 'd', (d) -> scope.line d.scores

				player.each (p) -> scope.intoPlayer p, this

			scope.intoPlayer = (player, element) ->
				cumulativeScore = d3.select element
					.select '.cumulative-score'
					.selectAll 'circle'
					.data (d) -> d.scores
				cumulativeScore.enter()
					.append 'circle'
					.attr 'r', scope.pointRadius
					.style 'stroke', scope.zScale player.name
					.style 'fill', 'white'
					.style 'stroke-width', '2.5px'
					.attr 'cx', (d) -> scope.xScale d.month
					.attr 'cy', (d) -> scope.yScale d.cumulative
				cumulativeScore.transition()
					.duration scope.duration
					.ease 'sin-in-out'
					.attr 'cx', (d) -> scope.xScale d.month
					.attr 'cy', (d) -> scope.yScale d.cumulative

				individualScore = d3.select element
					.selectAll '.individual-score'
					.data (d) -> d.scores
				individualScore.enter()
					.append 'rect'
					.attr 'class', 'individual-score'
					.attr 'width', scope.barWidth
					.attr 'height', scope.barHeight
					.attr 'x', scope.barX
					.attr 'y', scope.barY
					.style 'fill', scope.zScale player.name
				individualScore.transition()
					.duration scope.duration
					.ease 'sin-in-out'
					.attr 'height', scope.barHeight
					.attr 'x', scope.barX
					.attr 'y', scope.barY

			scope.barX = (score) ->
				scope.xScale(score.month) - (scope.barWidth / 2)

			scope.barY = (score) ->
				Math.min scope.yScale(0), scope.yScale(score.individual) - scope.yScale(scope.yScale.domain()[1])

			scope.barHeight = (score) ->
				Math.abs scope.yScale(0) - scope.yScale(score.individual)

			scope.$watch 'scores', (newScores) -> scope.update()