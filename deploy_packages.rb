require_relative 'helpers'

puts_line

target_dir    = env 'TARGET_DIR'
version       = env 'PACKAGES_VERSION'
packages_json = env 'PACKAGES_JSON_FILE', 'packages.json'

abort_unless(Dir.exists?(target_dir), "Dossier de destination '#{target_dir}' manquant.")
abort_if(version.nil? || version.empty?, 'Missing version')

puts_datas(
      'Destination' => target_dir,
      'Packages File' => packages_json,
      'Version' => version
)

puts_line

puts 'Creating packages :'

Dir['packages/*'].each do |package_dir|
   Dir.chdir(package_dir) do
      package_name = File.basename(package_dir) + '.tar.xz'
      target = File.join(target_dir, package_name)
      shell_v "tar -cJf #{target} *"
   end
end

if File.exists? packages_json
   puts_line
   puts 'Updating version file'
   File.open(File.join(target_dir, 'version'), 'w') do |f|
      f << version
   end
   puts 'Copying ' + packages_json
   File.open(File.join(target_dir, packages_json), 'w') do |f|
      f << File.read(packages_json)
   end
end

puts_line
puts 'Success !'
puts_line
