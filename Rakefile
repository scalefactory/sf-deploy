#!/usr/bin/env ruby
$:.push( File.join( File.dirname(__FILE__), 'lib' ) )

require 'pp'

require 'deploy/application'
require 'deploy/application/config'

application_config_base = ENV['APPLICATION_CONFIG_BASE'] || "/etc/sf-deploy.d"


class AppShim

    @app = nil

    def set_app(app)
        @app = app
    end

    def method_missing(meth, *args, &block)

        if @app.nil?
            $stderr.puts "You must choose an application by calling one of the application:* tasks first"
            exit -1
        end

        @app.send(meth, *args, &block)
    end

end

app = AppShim.new

namespace :application do

    Dir.entries( application_config_base ).select{ |f| f =~ /\.yml$/ }.each do |f|

        app_name = f.gsub(/\.yml$/, '')

        desc "Use the application called '#{app_name}'"
        task app_name.to_s do
        app.set_app( ScaleFactory::Deploy::Application.new( "#{application_config_base}/#{f}" ) )
        end

    end

end

desc "Enable debugging"
task :debug do
    app.logger.level = Logger::DEBUG
end


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

