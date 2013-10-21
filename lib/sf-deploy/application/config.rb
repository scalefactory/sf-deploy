module ScaleFactory
module Deploy

class Application::Config

    class ConfigValidationException < Exception
    end

    def initialize( config_file )

        require 'yaml'

        @config_file   = config_file
        @configuration = YAML::load_file( config_file )

        validate_config

    end

    def get( key )
        if @configuration.has_key?( key )
            if config_validation_rules[key].has_key?(:transform)
                return config_validation_rules[key][:transform].call( @configuration[key] )
            else
                return @configuration[key]
            end
        elsif config_validation_rules[key].has_key?(:default)
            return config_validation_rules[key][:default]
        else
            nil
        end
    end

    def to_s
        out = ""
        config_validation_rules.each do |key, rules|
            out << sprintf("%-20s: %s\n", key, get(key))
        end
        out
    end

    def method_missing( m, *args, &block )
        if config_validation_rules.has_key?( m.to_s )
            return get( m.to_s )
        else
            super
        end
    end

    private

    @config_file
    @configuration

    def config_validation_rules  
        
        {

            'name' => {
                :required => true,
            },

            'git_repo' => {
                :required => true,
            },

            'clone_path' => {
                :required => false,
                :default  => "/srv/deploy/clones/#{@configuration['name']}",
                :validate => Proc.new { |x|
                    unless x.start_with?('/')
                        raise ConfigValidationException, "Must be a fully qualified path"
                    end
                }
            },

            'deploy_to' => {
                :required => true,
                :validate => Proc.new { |x|
                    unless x.start_with?('/')
                        raise ConfigValidationException, "Must be a fully qualified path"
                    end
                }
            },

            'keep_releases' => {
                :require => false,
                :default => 5,
                :transform => Proc.new{ |x|
                    x.to_i
                }
            },

            'post_deploy_commands' => {
                :require => false,
                :default => {},
                :validate => Proc.new { |x|
                    unless x.is_a?(Hash)
                        raise ConfigValidationException, "Must be a Hash"
                    end
                }
            },

            'shared_children' => {
                :require => false,
                :default => [],
                :validate => Proc.new { |x|
                    unless x.is_a?(Array)
                        raise ConfigValidationException, "Must be an array"
                    end
                    x.each do |p|
                        if p.start_with?('/', '../')
                            raise ConfigValidationException, "Shared child #{p} is not a relative path"
                        end
                    end
                }
            },

        }

    end

    def validate_config

        config_problems = []

        config_validation_rules.each do |key, rules|

            if rules[:required]
                if ! @configuration.has_key?( key )
                    config_problems.push("'#{key}' is required but missing")
                    next
                end
            end

            if rules.has_key?(:validate) and @configuration.has_key?( key )
                begin
                    rules[:validate].call( @configuration[key] )
                rescue ConfigValidationException => e
                    config_problems.push("'#{key}' invalid: #{e.message}")
                end
            end

        end
               
        if config_problems.length > 0 
            $stderr.puts "There are problems with the configuration in #{@config_file}:" 
            $stderr.puts config_problems.join("\n")
            exit -1
        end




    end

end

end # module Deploy
end # module ScaleFactory
