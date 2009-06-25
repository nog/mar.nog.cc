#!/usr/bin/ruby

require '../mar'
set :run, false
set :env, :production
set :server, 'cgi'
set :logging, false

Rack::Handler::CGI.run Sinatra::Application