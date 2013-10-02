#!/usr/bin/env ruby
$:.push( File.join( File.dirname(__FILE__), 'lib' ) )

require 'pp'

require 'deploy/application'
require 'deploy/application/config'

unless ENV.has_key?('APPLICATION_CONFIG')
    $stderr.puts "ENV['APPLICATION_CONFIG'] must be set"
    exit -1
end

app = ScaleFactory::Deploy::Application.new( ENV['APPLICATION_CONFIG'] )

desc "Create or update the bare git clone for the application"
task :git_clone do
    app.update_git_clone
end

desc "Show available tags to deploy for the application"
task :show_tags do
    app.tags.each do |t|
        puts t
    end
end

desc "Show available branches to deploy for the application"
task :show_branches do
    app.branches.each do |b|
        puts b
    end
end


desc "Deploy a specific tag"
task :deploy_tag, :tag do |t,args|
    app.deploy_tag args.tag
end

desc "Deploy the latest from a branch"
task :deploy_branch, :branch do |t,args|
    app.deploy_branch args.branch
end

desc "Run the post-deploy commands"
task :run_post_deploy do
    app.run_post_deploy_commands
end

desc "Show the current release"
task :current_release do
    puts app.current_release
end

desc "Show the current release metadata"
task :current_metadata do
    puts app.get_metadata_for_current_release.inspect
end

