require 'bundler'
Bundler.require
require './application.rb'

FileUtils.mkdir_p 'tmp' unless File.exists?('tmp')
FileUtils.mkdir_p 'log' unless File.exists?('log')
log = File.new("log/sinatra.log", "a")
$stdout.reopen(log)
$stderr.reopen(log)

run Sinatra::Application
