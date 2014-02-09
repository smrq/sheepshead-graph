_ = require 'underscore'
d3 = require 'd3'

module.exports = (mod) ->
	mod.controller 'GraphCtrl', ($scope) ->
		$scope.scores = null
		$scope.loadData = (path) ->
			d3.json path, (error, rawScoreData) ->
				$scope.$apply ->
					$scope.scores = for name, cumulativeScores of rawScoreData.cumulative
						name: name
						scores: for [cumulative, individual], month in _.zip cumulativeScores, rawScoreData.individual[name]
							{ cumulative, individual, month }

		$scope.load1 = -> $scope.loadData "data.json"
		$scope.load2 = -> $scope.loadData "someData.json"
		$scope.load3 = -> $scope.loadData "lotsOfData.json"
