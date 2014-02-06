coffee = require 'gulp-coffee'
connectLivereload = require 'connect-livereload'
express = require 'express'
gulp = require 'gulp'
gutil = require 'gulp-util'
livereload = require 'gulp-livereload'
open = require 'gulp-open'
path = require 'path'
sass = require 'gulp-sass'
watch = require 'gulp-watch'

toBuild = gulp.dest './build/'

startExpress = ->
	app = express()
	app.use connectLivereload()
	app.use express.static path.join __dirname, 'build'
	app.listen 4000

gulp.task 'default', ->
	startExpress()

	gulp.src ['./src/*.css', './src/*.html', './src/*.json']
		.pipe watch()
		.pipe toBuild
		.pipe livereload()

	gulp.src ['./src/*.scss']
		.pipe watch()
		.pipe sass()
		.pipe toBuild
		.pipe livereload()

	gulp.src './src/*.coffee'
		.pipe watch()
		.pipe coffee().on 'error', gutil.log
		.pipe toBuild
		.pipe livereload()

	gulp.src './src/graph.html'
		.pipe open "", url: "http://localhost:4000/graph.html"