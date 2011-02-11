#!/usr/bin/env ruby
#
# Copyright (C) 2006 Rising Sun Pictures and Matthew Landauer.
# All Rights Reserved.
#  
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# $Id$

require 'optparse'
require 'fileutils'

opts = OptionParser.new
opts.banner = <<END_OF_STRING
Tag a release version based on the subversion revision and embed version
number in web application
Usage: #{$0} <version> <subversion revision>
END_OF_STRING
opts.on_tail("-h", "--help", "Show this message") do
  puts opts
  exit
end

begin
  opts.parse!(ARGV)
rescue
  puts opts
  exit 1
end

if ARGV.length != 2
  puts opts
  exit
end

version = ARGV[0]
svn_revision = ARGV[1].to_i

svn_root = "https://open.rsp.com.au/svn/earth"
tagged_location = "#{svn_root}/tags/#{version}"

# Tag version
system "svn cp #{svn_root}/trunk -r #{svn_revision} #{tagged_location} -m'release/tag.rb automated tagging of version #{version} from subversion revision #{svn_revision}'"
# Checkout tagged version
system "svn co #{tagged_location}/app/helpers helpers"

text = File.open("helpers/application_helper.rb") {|f| f.read}
text = text.sub(/\searth_version_svn/, "'#{version}'")
File.open("helpers/application_helper.rb", "w") {|f| f.write(text)}

system "svn commit helpers -m 'release/tag.rb Addition of version #{version} in code'"
FileUtils.rm_rf 'helpers'

puts "Version #{version} is tagged and ready to go at #{tagged_location}"
