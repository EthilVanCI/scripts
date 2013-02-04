ARGV[0] =~ %r{^(?:.+/)?([^/]+?)$}
branch = $1

ci_id = `git config ci.#{branch}`.strip
ci_id = `git config ci.all`.strip if ci_id.empty?

if ci_id.empty?
   puts 'No configured ci key for this repository.'
   puts 'Skipping.'
   exit 0
end

require_relative 'teamcity'

puts "Triggering CI Build '#{ci_id}' ..."

TeamCity.trigger(ci_id, branch)
