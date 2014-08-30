gulp = require 'gulp'
gutil = require 'gulp-util'
livereload = require 'gulp-livereload'
nodemon = require 'gulp-nodemon'
plumber = require 'gulp-plumber'
gwebpack = require 'gulp-webpack'
less = require 'gulp-less'
autoprefixer = require 'gulp-autoprefixer'
rimraf = require 'rimraf'

root = __dirname
src_path = "#{root}/src"
components_path = "#{root}/bower_components"
modules_path = "#{root}/node_modules"
semantic_path = "#{components_path}/semantic/build/packaged"
dist_path = "#{root}/dist"

err = (x...) -> gutil.log(x...); gutil.beep(x...)

webpack = (name, ext, watch) ->
  options =
#    bail: true
    watch: watch
    cache: true
    devtool: "source-map"
    output:
      filename: "#{name}.js"
      sourceMapFilename: "[file].map"
    resolve:
      extensions: ["", ".webpack.js", ".web.js", ".js", ".jsx", ".coffee", ".cjsx"]
      modulesDirectories: [components_path, modules_path]
    module:
      loaders: [
        {
          test: /\.coffee$/
          loader: "coffee-loader"
        }
        {
          test: /\.cjsx$/
          loader: "transform?coffee-reactify"
        }
        {
          test: /\.jsx$/
          loader: "transform?reactify"
        }
      ]
    externals: [(context, request, ecb) ->
      # externs = [/^foo.*/]
      externs = []
      match = externs.some (x) -> x.test request
      if match then ecb(null, "amd " + request) else ecb()
      return
    ]

  gulp.src("#{src_path}/#{name}.#{ext}")
  .pipe(gwebpack(options))
  .pipe(gulp.dest(dist_path))


js = (watch) -> webpack("client", "cjsx", watch)

gulp.task 'js', -> js(false)

gulp.task 'js-dev', -> js(true)

gulp.task 'css', ->
  gulp.src("#{src_path}/styles.less")
  .pipe(plumber())
  .pipe(less(
    paths: [components_path, modules_path]
  ))
  .on('error', err)
  .pipe(autoprefixer("last 2 versions", "ie 8", "ie 9"))
  .pipe(gulp.dest(dist_path))

gulp.task 'clean', (callback) ->
  rimraf.sync(dist_path)
  callback()

gulp.task 'copy', ->
  gulp.src("#{src_path}/*.html").pipe(gulp.dest(dist_path))
  gulp.src("#{src_path}/favicon.ico").pipe(gulp.dest(dist_path))
  gulp.src("#{semantic_path}/fonts/**/*").pipe(gulp.dest("#{dist_path}/fonts"))
  gulp.src("#{semantic_path}/images/**/*").pipe(gulp.dest("#{dist_path}/images"))

gulp.task 'build', ['clean', 'copy', 'css', 'js']

server_main = "#{src_path}/server.coffee"
gulp.task 'server', ->
  nodemon
    script: server_main
    watch: [server_main]
    env:
      PORT: process.env.PORT or 3000

gulp.task 'dev', ['copy', 'css', 'watch', 'server', 'js-dev']

gulp.task 'default', ['dev']

gulp.task 'watch', ->
  livereload.listen()
  gulp.watch("#{dist_path}/**").on('change', livereload.changed)
  # gulp.watch ["#{src_path}/**/*.coffee", "#{src_path}/**/*.cjsx", "#{src_path}/**/*.js"], ['js-dev']
  gulp.watch ["#{src_path}/**/*.less"], ['css']
  gulp.watch ["#{src_path}/**/*.html"], ['copy']
