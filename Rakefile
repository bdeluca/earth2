# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

# Wrap this around in case the user doesn't have CI::Reporter
# This is only useful for Continuous Integration and shouldn't
# be mandatory to use Earth
ci_reporter = Gem.cache.search('ci_reporter').first
if ci_reporter
  gem 'ci_reporter'
  require 'ci/reporter/rake/test_unit'
end

##
# Run a single test in Rails.
#
#   rake blogs_list
#   => Runs test_list for BlogsController (functional test)
#
#   rake blog_create
#   => Runs test_create for BlogTest (unit test)

rule "" do |t|
  if /(.*)_([^.]+)$/.match(t.name)
    file_name = $1
    test_name = $2
    if File.exist?("test/unit/#{file_name}_test.rb")
      file_name = "unit/#{file_name}_test.rb" 
    elsif File.exist?("test/functional/#{file_name}_controller_test.rb")
      file_name = "functional/#{file_name}_controller_test.rb" 
    else
      raise "No file found for #{file_name}" 
    end
    sh "ruby -Ilib:test test/#{file_name} -n /^test_#{test_name}/" 
  end
end
