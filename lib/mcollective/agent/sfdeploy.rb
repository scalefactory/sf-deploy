
require 'sf-deploy/application'
require 'sf-deploy/application/config'
require 'stringio'
require 'logger'

module MCollective
    module Agent
        class Sfdeploy < RPC::Agent

            def startup_hook
            end

            %w(update_git_clone show_tags show_branches deploy_tag deploy_branch run_post_deploy current_metadata).each do |act|

                action act do

                    sf_deploy   = config.pluginconf["sfdeploy.binary"] || "sf-deploy"
                    deploy_user = config.pluginconf["sfdeploy.user"]   || nil
                     
                    command = "#{sf_deploy} -a #{request[:application]} -v "
                    command << "-b #{request[:branch]} " if request[:branch]
                    command << "-t #{request[:tag]} "    if request[:tag]
                    command << "-g #{request[:groups]} " if request[:groups]
                    command << act

                    if deploy_user
                        to_run = "su #{deploy_user} -c \"#{command}\""
                    else
                        to_run = command
                    end

                    Log.debug( to_run )

                    if act == 'show_tags'

                        out = ""
                        reply[:status] = run( to_run, :stdout => out, :stderr => :err, :chomp => true )
                        reply[:tags]   = out.split("\n")

                    elsif act == 'show_branches'

                        out = ""
                        reply[:status]   = run( to_run, :stdout => out, :stderr => :err, :chomp => true )
                        reply[:branches] = out.split("\n")

                    elsif act == 'current_metadata'

                        out = ""
                        reply[:status]   = run( to_run, :stdout => out, :stderr => :err, :chomp => true )
                        reply[:metadata] = out

                    else

                        reply[:status] = run( to_run, :stdout => :out, :stderr => :err, :chomp => true )

                    end
                        
                    reply

                end

            end

        end
    end
end
