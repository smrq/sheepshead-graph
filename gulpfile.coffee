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
		.pipe watch()
		.pipe gulp.dest BUILD_FOLDER
		.pipe livereload()

gulp.task 'styles', ->
	gulp.src './src/*.scss'
		.pipe watch()
		.pipe sass()
		.pipe rename 'bundle.css'
		.pipe gulp.dest BUILD_FOLDER
		.pipe livereload()

gulp.task 'scripts', ->
	gulp.src './src/main.coffee', read: false
		.pipe watch()
		.pipe browserify
			transform: ['coffeeify']
			extensions: ['.coffee']
		.pipe rename 'bundle.js'
		.pipe gulp.dest BUILD_FOLDER
		.pipe livereload()

gulp.task 'markup', ->
	gulp.src './src/*.html'
		.pipe watch()
		.pipe htmlreplace
			styles: 'bundle.css'
			scripts: 'bundle.js'
		.pipe gulp.dest BUILD_FOLDER

gulp.task 'openBrowser', ->
	startExpress()
	gulp.src './src/graph.html'
		.pipe open "", url: "http://localhost:#{EXPRESS_PORT}/graph.html"

gulp.task 'default', ['static', 'styles', 'scripts', 'markup', 'openBrowser' ]
