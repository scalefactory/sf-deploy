Gem::Specification.new do |s|
    s.name        = 'sf-deploy'
    s.version     = '0.0.1'
    s.date        = '2013-10-03'
    s.summary     = 'Pull-based deployment tool'
    s.description = 'Pull-based software deployment from git using mcollective'
    s.authors     = [ 'Jon Topper' ]
    s.email       = 'jon@scalefactory.com'

    files = `git ls-files`.split("\n")
    ignore = %w{Gemfile Rakefile .gitignore}

    files.delete_if do |f|
        ignore.any? do |i|
            File.fnmatch(i, f, File::FNM_PATHNAME) ||
            File.fnmatch(i, File.basename(f), File::FNM_PATHNAME)
        end
    end

    s.files = files

    s.executables << 'sf-deploy'
    s.homepage    = 'http://github.com/scalefactory/sf-deploy'
    s.require_path = 'lib'
end
