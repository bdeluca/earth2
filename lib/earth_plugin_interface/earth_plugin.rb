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

class InvalidEarthPluginError < RuntimeError
end

class PluginMethodNotImplementedError < RuntimeError
end

class EarthPlugin
  @@on_inheritance_block = nil

  def self.on_inheritance(&block)
    @@on_inheritance_block = block
  end

  def self.inherited(child) #:nodoc:
    @@on_inheritance_block.call(child) if @@on_inheritance_block
    super
  end

  def self.plugin_name
    raise PluginMethodNotImplementedError
  end

  def self.validate_plugin_class(plugin_class)

    begin
      plugin_name = plugin_class.plugin_name
    rescue PluginMethodNotImplementedError
      raise InvalidEarthPluginError, "The plugin does not implement the plugin_name method"
    rescue
      raise InvalidEarthPluginError, err
    end

    begin
      plugin_version = plugin_class.plugin_version
      if plugin_version.class != Fixnum
        raise InvalidEarthPluginError, "The plugin_version method implemented by this plugin does not return a fixnum"
      end
    rescue PluginMethodNotImplementedError
      raise InvalidEarthPluginError, "The plugin does not implement the plugin_version method"
    rescue => err
      raise InvalidEarthPluginError, err
    end

  end
end

