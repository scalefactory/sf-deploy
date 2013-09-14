module ScaleFactory
module Deploy

require 'fileutils'
require 'pathname'
require 'logger'

class Application

    def initialize( config_file )
        @conf   = Application::Config.new( config_file )
        @logger = Logger.new(STDERR)
        @logger.level = Logger::DEBUG
    end

    def create_clone_path
        @logger.info("#{__method__}: Creating directory #{@conf.clone_path}")
        FileUtils.mkdir_p( @conf.clone_path ) unless File.directory?( @conf.clone_path )
    end

    def initial_git_clone
        create_clone_path
        if File.exists?( File.join( @conf.clone_path, 'config' ) )
            @logger.debug("#{__method__}: Git clone already created")
            return
        end
        @logger.info("#{__method__}: Cloning git repo from #{@conf.git_repo}")
        system( "git clone --mirror #{@conf.git_repo} #{@conf.clone_path}" )
        @logger.debug("Clearing cached git data")
        @cache = {}
    end

    def update_git_clone
        initial_git_clone
        @logger.info("#{__method__}: Fetching changes from upstream")
        system( "cd #{@conf.clone_path} && git fetch" )
        @cache = {}
    end

    def tags
        @cache['tags'] ||= get_tags
    end

    def deploy_tag( tag )

        update_git_clone

        unless tags.index(tag)
            raise "The tag '#{tag}' doesn't exist in the repo at '#{@conf.git_repo}'"
        end

        timestamp = Time.now.strftime('%Y%m%d%H%M%S')
        deploy_path = get_path_for_release( timestamp )

        if File.exists?( deploy_path )
            raise "The deployment path #{deploy_path} already exists"
        end

        FileUtils.mkdir_p( deploy_path ) 

        system( "git archive #{tag} --remote=#{@conf.clone_path} | tar -C #{deploy_path} -xv" )

        link_release( timestamp )
        clean_old_releases

    end

    def releases
        Dir.glob( "#{@conf.deploy_to}/releases/*" ).map { |f|
            Pathname.new(f).basename.to_s
        }
    end

    def current_release
        begin
            return Pathname.new( "#{@conf.deploy_to}/current" ).realpath.basename.to_s
        rescue Errno::ENOENT
            return nil
        end
    end

    def link_release( release )

        deploy_path = get_path_for_release( release ) 
        symlink     = "#{@conf.deploy_to}/current"

        File.unlink( symlink )
        FileUtils.ln_sf( deploy_path, symlink )

    end

    def clean_old_releases

        old_releases = releases.sort.reverse

        if current_release
            old_releases.delete current_release
        end

        old_releases.reverse.slice(0, old_releases.length - @conf.keep_releases).each do |r|
            FileUtils.rm_rf( get_path_for_release(r) )
        end
        
    end



    private

    @cache = {}

    def get_tags
        output = `cd #{@conf.clone_path} && git tag`
        output.split("\n")
    end

    def get_path_for_release( release )
        File.join( @conf.deploy_to, "releases", release )
    end

end

end
end
