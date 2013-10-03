$:.push( '/vagrant/deploy/lib' )

require 'deploy/application'
require 'deploy/application/config'
require 'stringio'
require 'logger'

module MCollective
    module Agent
        class Sfdeploy < RPC::Agent

            def startup_hook
                @application_config_base = "/etc/sf-deploy.d" # TODO config file
                @application = {}
                Dir.entries( @application_config_base ).select{ |f| f =~ /\.yml$/ }.each do |f|
                    Log.info( "Found sfdeploy config: #{@application_config_base}/#{f}" )
                    app_name = f.gsub(/\.yml$/, '')
                    @application[app_name] = ScaleFactory::Deploy::Application.new(
                       "#{@application_config_base}/#{f}"
                    )
                end
            end

            %w(git_clone show_tags show_branches deploy_tag deploy_branch run_post_deploy current_metadata).each do |act|

                action act do
                    do_action( request[:application], act.to_sym, request, reply )
                end

            end

            private

            def do_action( application_name, action, request, reply )

                unless @application.has_key?( application_name )
                    reply.fail "No such application '#{application_name}'"
                    return reply
                end

                application = @application[application_name]

                case action

                    when :git_clone
                        application.update_git_clone

                    when :show_tags
                        reply[:tags] = application.tags

                    when :show_branches
                        reply[:branches] = application.branches

                    when :deploy_tag
                        application.deploy_tag request[:tag]

                    when :deploy_branch
                        application.deploy_branch request[:branch]

                    when :run_post_deploy
                        application.run_post_deploy_commands

                    when :current_metadata
                        reply[:metadata] = application.get_metadata_for_current_release

                end

                reply

            end


        end
    end
end
