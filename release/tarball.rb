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
Checkout a tagged version of Earth from subversion and create a tarball from it 
Usage: #{$0} <version>
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

if ARGV.length != 1
  puts opts
  exit
end

version = ARGV[0]

svn_root = "https://open.rsp.com.au/svn/earth"
tagged_location = "#{svn_root}/tags/#{version}"

system "svn export #{tagged_location} earth-#{version}"
system "tar zcvf earth-#{version}.tar.gz earth-#{version}"
FileUtils.rm_rf "earth-#{version}"