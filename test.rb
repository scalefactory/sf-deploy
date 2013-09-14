#!/usr/bin/env ruby
$:.push( File.join( File.dirname(__FILE__), 'lib' ) )

require 'pp'

require 'deploy/application'
require 'deploy/application/config'

app = ScaleFactory::Deploy::Application.new( 'hacking/config.yml' )
#app.create_clone_path
#app.initial_git_clone
app.update_git_clone
#pp app.tags

#app.deploy_tag 'v1.3.1'

