#!/usr/bin/ruby

require File.dirname(__FILE__) + '/../mar'
set :run, false
set :environment, :production
set :server, 'cgi'
set :logging, false

Rack::Handler::CGI.run Sinatra::Application
