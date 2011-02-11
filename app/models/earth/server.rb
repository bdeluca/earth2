# Copyright (C) 2007 Rising Sun Pictures and Matthew Landauer
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require 'socket'

module Earth

  class Server < ActiveRecord::Base
    has_many :directories, :dependent => :delete_cascade, :order => :lft

    @@config = nil    
    def self.config
      @@config = ApplicationController::webapp_config unless @@config
      @@config
    end
    
    def self.heartbeat_grace_period
      self.config["heartbeat_grace_period"].to_i
    end

    def Server.this_server
      Server.find_or_create_by_name(ENV["EARTH_HOSTNAME"] || this_hostname)
    end
    
    def Server.this_hostname
      Socket.gethostbyname(Socket.gethostname)[0]
    end
    
    def size
      size_sum = Size.new(0, 0, 0)
      Earth::Directory.roots_for_server(self).each do |d|
        size_sum += d.size
      end
      size_sum
    end

    def has_files?
      size.count > 0
    end
    
    def heartbeat
      self.heartbeat_time = Time.now.utc
      save!
    end
    
    def daemon_alive?
      if heartbeat_time.nil? or daemon_version.nil?
        false
      else
        (heartbeat_time + heartbeat_interval + Earth::Server.heartbeat_grace_period) >= Time::now
      end
    end

    def cache_complete?
      roots = Earth::Directory.roots_for_server(self) 
      (not roots.empty?) and roots.all? { |d| d.cache_complete? and not d.children.empty? }
    end
  end
end
