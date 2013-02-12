require 'pathname'
require 'yaml'
require_relative 'helpers'

class UpdateSite

   SOURCE_ROOT = Pathname.new('')
   BRANCH      = env 'GIT_BRANCH'
   TARGET_ROOT = Pathname.new File.expand_path env 'TARGET_DIR'

   Version = Struct.new(:sha, :date)

   attr_reader :name

   def self.resolve_dependencies_in(list)
      list.each { |ps| ps.resolve_dependencies(list)  }
   end

   def initialize(name, config)
      @name              = name
      @deps_names        = config['dependencies']
      @targets           = config['targets']
   end

   def resolve_dependencies(list)
      @dependencies = @deps_names.map do |dep_name|
         list.find { |ps| ps.name == dep_name }
      end.compact
   end

   def version
      @version ||= begin
         log = `git log --pretty=format:'%H\n%ct' -n 1 -- #@name`.strip
         sha, date = log.split("\n")
         Version.new(sha, Time.at(date.to_i))
      end
   end

   def up_to_date?
      deployed_version.date >= dependencies_version.date
   end

   def need_deployment?
      deployed_version.date < version.date
   end

   def update
      do_update if has_target? and !up_to_date?
   end

   def force_update
      do_update(true)
   end

private

   def do_update(force = false)
      puts "Updating #@name"
      deploy if force or need_deployment?
      update_version
      puts 'Done'
      puts_line
   end

   def deploy
      deploy_packages
      deploy_files
   end

   def deploy_packages
      packages = SOURCE_ROOT.join(name).join('packages')
      return unless packages.directory?
      packages.each_child { |package| deploy_package(package) }
   end

   def deploy_package(package)
      archive = target_path.join("#{package.basename}.tar.xz")
      target_path.mkpath
      Dir.chdir(package.to_s) { shell_v "tar -cJf #{archive} *" }
   end

   def deploy_files
      files = SOURCE_ROOT.join(name).join('files')
      return unless files.directory?
      files.each_child { |file| deploy_file(file) }
   end

   def deploy_file(file)
      target_path.mkpath
      shell_v "cp #{file.to_s} #{target_path.join(file.basename)}"
   end

   def update_version
      puts "Updating version file with '#{dependencies_version.sha}'"
      target_path.mkpath
      file = target_path.join('version')
      File.open(file, 'w') { |f| f << dependencies_version.sha }
   end

   def has_target?
      !target.nil?
   end

   def target
      @targets[BRANCH] || @targets['*'] || nil
   end

   def target_path
      TARGET_ROOT.join(target)
   end

   def deployed_version
      @deployed_version ||= begin
         file = target_path.join('version')
         if file.exist?
            sha = file.read
            date = `git show --pretty=format:'%ct' #{sha}`.strip
            Version.new(sha, Time.at(date.to_i))
         else
            Version.new('', Time.at(0))
         end
      end
   end

   def dependencies_version
      @last_version ||= [version, *@dependencies.map(&:version)].max_by &:date
   end
end

abort_unless(File.exists?('config.yml'), 'Missing config.yml')
config = YAML.load_file 'config.yml'

@sites = config.map do |name, packageset_config|
   UpdateSite.new(name, packageset_config)
end

UpdateSite.resolve_dependencies_in(@sites)

puts_line
puts "Checking for updates ... "
puts_line
@sites.each do |ps|
   ps.update
end
