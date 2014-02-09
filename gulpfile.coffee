browserify = require 'gulp-browserify'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
connectLivereload = require 'connect-livereload'
express = require 'express'
gulp = require 'gulp'
gutil = require 'gulp-util'
htmlreplace = require 'gulp-html-replace'
jade = require 'gulp-jade'
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

content = ->
	gulp.src './src/*.json'
		.pipe gulp.dest BUILD_FOLDER

styles = ->
	gulp.src './src/*.scss'
		.pipe sass()
		.pipe concat 'bundle.css'
		.pipe gulp.dest BUILD_FOLDER

scripts = ->
	gulp.src './src/main.coffee', read: false
		.pipe browserify
			transform: ['coffeeify', 'debowerify']
			extensions: ['.coffee']
		.pipe rename 'bundle.js'
		.pipe gulp.dest BUILD_FOLDER

markup = ->
	gulp.src './src/*.jade'
		.pipe jade pretty: true
		.pipe htmlreplace
			styles: 'bundle.css'
			scripts: 'bundle.js'
		.pipe gulp.dest BUILD_FOLDER

gulp.task 'content', content
gulp.task 'styles', styles
gulp.task 'scripts', scripts
gulp.task 'markup', markup
gulp.task 'build', ['content', 'styles', 'scripts', 'markup']

gulp.task 'watch', ['build'], ->
	gulp.watch './src/*.json', -> content().pipe livereload()
	gulp.watch './src/*.scss', -> styles().pipe livereload()
	gulp.watch './src/*.coffee', -> scripts().pipe livereload()
	gulp.watch './src/*.jade', -> markup().pipe livereload()

gulp.task 'browse', ['watch'], ->
	startExpress()
	gulp.src './src/graph.jade'
		.pipe open "", url: "http://localhost:#{EXPRESS_PORT}/graph.html"

gulp.task 'default', ['build']
