angular = require 'angular'

app = angular.module 'app', []

require('./lineScoreGraph')(app)
require('./graphCtrl')(app)