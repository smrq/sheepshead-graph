browserify = require 'gulp-browserify'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
connectLivereload = require 'connect-livereload'
express = require 'express'
gulp = require 'gulp'
gutil = require 'gulp-util'
htmlreplace = require 'gulp-html-replace'
livereload = require 'gulp-livereload'
open = require 'gulp-open'
path = require 'path'
rename = require 'gulp-rename'
sass = require 'gulp-sass'
watch = require 'gulp-watch'

BUILD_FOLDER = './build/'
EXPRESS_PORT = 4000

startExpress = ->
	app = express()
	app.use connectLivereload()
	app.use express.static path.join __dirname, BUILD_FOLDER
	app.listen EXPRESS_PORT

gulp.task 'static', ->
	gulp.src './src/*.json'
		.pipe gulp.dest BUILD_FOLDER
		.pipe livereload()

gulp.task 'styles', ->
	gulp.src './src/*.scss'
		.pipe sass()
		.pipe concat 'bundle.css'
		.pipe gulp.dest BUILD_FOLDER
		.pipe livereload()

gulp.task 'scripts', ->
	gulp.src './src/main.coffee', read: false
		.pipe browserify
			transform: ['coffeeify']
			extensions: ['.coffee']
		.pipe rename 'bundle.js'
		.pipe gulp.dest BUILD_FOLDER
		.pipe livereload()

gulp.task 'markup', ->
	gulp.src './src/*.html'
		.pipe htmlreplace
			styles: 'bundle.css'
			scripts: 'bundle.js'
		.pipe gulp.dest BUILD_FOLDER
		.pipe livereload()

gulp.task 'watch', ->
	gulp.watch './src/*.json', -> gulp.run 'static'
	gulp.watch './src/*.scss', -> gulp.run 'styles'
	gulp.watch './src/*.coffee', -> gulp.run 'scripts'
	gulp.watch './src/*.html', -> gulp.run 'markup'

gulp.task 'browse', ->
	startExpress()
	gulp.src './src/graph.html'
		.pipe open "", url: "http://localhost:#{EXPRESS_PORT}/graph.html"

gulp.task 'default', ['static', 'styles', 'scripts', 'markup' ]
gulp.task 'dev', ['default', 'watch', 'browse']
