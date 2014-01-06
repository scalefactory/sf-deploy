module ScaleFactory
module Deploy

require 'fileutils'
require 'pathname'
require 'yaml'
require 'logger'

class Application

    class ShellCommandException < StandardError
    end

    attr_accessor :logger

    def initialize( config_file, logger = nil )
        @conf         = Application::Config.new( config_file )
        @logger       = logger || Logger.new(STDERR)
        @logger.level = Logger::INFO
        @cache        = {}
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
        logged_system( "git clone --mirror #{@conf.git_repo} #{@conf.clone_path}" )
        @logger.debug("Clearing cached git data")
        @cache = {}
    end

    def update_git_clone
        initial_git_clone
        @logger.info("#{__method__}: Fetching changes from upstream")
        logged_system( "cd #{@conf.clone_path} && git fetch" )
        @cache = {}
    end

    def tags
        @cache['tags'] ||= get_tags
    end

    def branches
        @cache['branches'] || get_branches
    end

    def deploy_sha( sha, metadata = {} )

        @logger.info("#{__method__}: Deploying #{sha}")

        create_deploy_base_paths

        timestamp = Time.now.strftime('%Y%m%d%H%M%S')
        deploy_path = get_path_for_release( timestamp )

        if File.exists?( deploy_path )
            raise "The deployment path #{deploy_path} already exists"
        end

        @logger.info("#{__method__}: Making directory #{deploy_path}")
        FileUtils.mkdir_p( deploy_path ) 

        @logger.info("#{__method__}: Using 'git archive' to extract code for deploy")
        logged_system( "git archive #{sha} --remote=#{@conf.clone_path} | tar -C #{deploy_path} -xv" )

        @logger.info("#{__method__}: Linking shared children")
        @conf.shared_children.each do |c|

            if !File.exists?( File.join( shared_path, c ) ) and @conf.copy_absent_shared_children
                @logger.info("#{__method__}: Absent shared child #{c} - copying from checkout")
                FileUtils.cp_r( File.join( deploy_path, c ), File.join( shared_path, c ) )
            end

            @logger.info("#{__method__}: Linking shared child #{c}")

            if File.exists?( File.join( deploy_path, c ) )
                @logger.info("#{__method__}: (Deleting existing target '#{c}' from deploy first)")
                FileUtils.rm_rf( File.join( deploy_path, c ) )
            end

            File.symlink( File.join( shared_path, c ), File.join( deploy_path, c ) )

        end


        @logger.info("#{__method__}: Writing deploy metadata")

        metadata['sha'] = sha

        File.open( "#{deploy_path}/.deploy_metadata", "w" ) do |f|
            f.write YAML::dump(metadata)
        end

        link_release( timestamp )
        clean_old_releases

    end

    def deploy_tag( tag )

        unless tags.index(tag)
            raise "The tag '#{tag}' doesn't exist in the repo at '#{@conf.git_repo}'"
        end

        deploy_sha( get_sha_from_ref(tag), { 'tag' => tag })

    end

    def deploy_branch( branch )

        unless branches.index(branch)
            raise "The branch '#{branch}' doesn't exist in the repo at '#{@conf.git_repo}'"
        end

        deploy_sha( get_sha_from_ref(branch), { 'branch' => branch })

    end

    def releases
        available_releases = Dir.glob( "#{@conf.deploy_to}/releases/*" ).map { |f|
            release = Pathname.new(f).basename.to_s
            @logger.debug("#{__method__}: Found release: '#{release}'")
            release
        }
    end

    def current_release
        begin
            current = Pathname.new( "#{@conf.deploy_to}/current" ).realpath.basename.to_s
            @logger.info("#{__method__}: Current release read as '#{current}'")
            return current
        rescue Errno::ENOENT
            @logger.info("#{__method__}: No 'current' symlink")
            return nil
        end
    end

    def get_metadata_for_release( release )
        deploy_path = get_path_for_release( release )
        return YAML::load_file( "#{deploy_path}/.deploy_metadata" )
    end

    def get_metadata_for_current_release
        get_metadata_for_release( current_release )
    end

    def link_release( release )

        deploy_path = get_path_for_release( release ) 
        symlink     = "#{@conf.deploy_to}/current"

        if File.exists?( symlink )
            @logger.info("#{__method__}: Removing old /current link")
            File.unlink( symlink )
        end
        @logger.info("#{__method__}: Linking #{symlink} to #{deploy_path}")
        FileUtils.ln_sf( deploy_path, symlink )

    end

    def clean_old_releases

        old_releases = releases.sort.reverse

        if current_release
            old_releases.delete current_release
        end

        to_remove = old_releases.reverse.slice(0, old_releases.length - @conf.keep_releases) || []

        to_remove.each do |r|
            @logger.info("#{__method__}: Removing old release #{r}")
            FileUtils.rm_rf( get_path_for_release(r) )
        end
        
    end

    def run_post_deploy_commands( groups )

        missing_groups = []
        groups.each do |group|
            if ! @conf.post_deploy_commands.has_key?(group)
                missing_groups << group
            end
        end

        unless missing_groups.empty?
            missing_groups.each do |group|
                @logger.error("#{__method__}: #{group} group does not exist")
            end
            exit 1
        end

        @conf.post_deploy_commands.sort.map do |group_key,group_val|
            groups.each do | group |
                if group_key == group
                    @logger.info("#{__method__}: Running #{group_key} commands")
                    group_val.sort.each do |command|
                        logged_system("cd #{@conf.deploy_to}/current && #{command}")
                    end
                end
            end
        end

    end



    private

    @cache = {}
    
    # TODO how do we stop git over ssh being interactive?

    def get_tags
        @logger.info("#{__method__}: Getting tags from git")
        output = `cd #{@conf.clone_path} && git tag`
        tags = output.split("\n")
        tags.each do |t|
            @logger.debug("#{__method__}: #{t}")
        end
        tags
    end

    def get_branches
        @logger.info("#{__method__}: Getting branches from git")
        output = `cd #{@conf.clone_path} && git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)'`
        branches = output.split("\n")
        branches.each do |b|
            @logger.debug("#{__method__}: #{b}")
        end
        branches
    end

    def get_sha_from_ref(ref)
        output = `cd #{@conf.clone_path} && git rev-list -1 #{ref}`
        sha = output.split("\n").first
        @logger.info("#{__method__}: SHA sum for #{ref} is #{sha}")
        sha
    end

    def get_path_for_release( release )
        File.join( @conf.deploy_to, "releases", release )
    end
    
    def shared_path
        File.join( @conf.deploy_to, "shared" )
    end

    def create_deploy_base_paths

        unless File.exists?( @conf.deploy_to )
            @logger.info("#{__method__}: Creating #{@conf.deploy_to}")
            FileUtils.mkdir_p( @conf.deploy_to )
        end

        unless File.exists?( shared_path )
            @logger.info("#{__method__}: Creating #{shared_path}")
            FileUtils.mkdir_p( shared_path )
        end

    end

    def logged_system(*args)

        @logger.info("#{__method__}: #{args.join(' ')}")

        process = IO.popen( args.join(' ') + " 2>&1" ) do |io|

            io.each do |line|

                @logger.info( line.chomp )

            end

            io.close

            @logger.debug( "Exit status: #{$?.to_i}" )

            if $? != 0
                raise ShellCommandException, "Execution of \"#{args.join(' ')}\" failed"
            end

        end

    end

end

end # module
end # module
