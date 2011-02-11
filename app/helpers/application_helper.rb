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

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def self_and_ancestors_up_to(directory, parent_dir)
    if parent_dir.nil?
      directory.self_and_ancestors
    elsif directory.id == parent_dir.id
      [ directory ]
    else
       directory.self_and_ancestors_up_to(parent_dir) + [ parent_dir ]
    end
  end

  def current_total_size
    if @directory
      @directory.size.bytes
    elsif @server
      @server.size.bytes
    else
      Earth::Server::find(:all).map { |server| server.size.bytes }.sum
    end
  end


  def ApplicationHelper::human_units_of(size)
    case 
      when size < 1.kilobyte: 'Bytes'
      when size < 1.megabyte: 'KB'
      when size < 1.gigabyte: 'MB'
      when size < 1.terabyte: 'GB'
      else                    'TB'
    end
  end

  def ApplicationHelper::human_size(size)
    units = human_units_of(size)
    "#{human_size_in(units, size)} #{units}"
  end
  
  def ApplicationHelper::human_size_in(units, size)
    scaled = scale_for_human_size(units, size)
    text = ('%.1f' % scaled).sub('.0', '')
    if text == '0' && scaled > 0
      return '> 0'
    else
      return text
    end
  end
  
  def bar(value, max_value, options)
    # Hack to deal with divide by zero
    if max_value == 0
      max_value = 1
    end
    xml = Builder::XmlMarkup.new
    xml.div("class" => "bar-outer") do
      xml.div(".", "class" => options[:class] || "bar", "style" => "width: #{(100 * value / max_value).to_i}%")
    end
  end

  def breadcrumbs_with_server_and_directory(server = nil, directory = nil)
    s = link_to_unless_current("root", :overwrite_params => {:server => nil, :path => nil, :page => nil})
    if server
      s += ' &#187 '
      s += link_to_unless_current(server.name, :overwrite_params => {:server => server.name, :path => nil, :page => nil})
    end
    if directory
      s += ' &#187 '
      # Note: need to reverse ancestors with behavior compatible to nested_set
      # (as opposed to better_nested_set)
      path_components = directory.ancestors.reverse

      # Add top-most directory, if present
      if not path_components.empty?
        s += link_to(path_components[0][:name], :overwrite_params => {:path => path_components[0].path, :page => nil}) + '/'

        # Remove top-most directory from component list
        path_components = path_components[1..-1]
      end

      # Remove top-most directories from component list until breadcrumb size is acceptable
      # Make sure that at least the parent directory is still in breadcrumb
      stripped = false
      while path_components.size > 1 \
        and path_components.inject(s.size) { |sum, dir| sum += dir.name.size+1 } > ApplicationController::webapp_config["max_breadcrumb_length"].to_i
        path_components = path_components[1..-1]
        stripped = true
      end

      s += ".../" if stripped

      path_components.each do |dir|
        s += link_to(dir[:name], :overwrite_params => {:path => dir.path, :page => nil}) + '/'
      end
      s += h(directory[:name])
    end
    return s
  end

  # This depends on the application running from a checked out svn version and
  # the command "svnversion" being available on the path.
  def ApplicationHelper::earth_version_svn
    begin
      revision = IO::popen("svnversion #{RAILS_ROOT}") { |f| f.readline }
    rescue
      # If svnversion isn't available
      revision = "unknown"
    end
    "revision " + revision
  end
  
  def ApplicationHelper::earth_version
   '0.2'
  end

  def ApplicationHelper::get_browser_warning(request)
    begin
      RAILS_DEFAULT_LOGGER.debug("user agent is #{request.user_agent}, accept is #{request.accept}")
      if request.user_agent.downcase =~ /firefox\/1.5/
        "WARNING: You appear to be using Firefox 1.5 - SVG support in this browser is flaky at best. Use <a href='http://www.mozilla.com/en-US/firefox/'>Firefox 2.0</a> for better results."
      else
        nil
      end
    rescue
      nil
    end
  end
  
  def tab_info
    [ 
      { :title => "navigation", :controller => "browser", :action => "show" },
      { :title => "all files",  :controller => "browser", :action => "flat" },
      { :title => "radial",    :controller => "graph",   :action => "index" }
    ]
  end

private

  def ApplicationHelper::scale_for_human_size(units, size)
    case
      when units == 'Bytes': size
      when units == "KB": size / 1.0.kilobyte
      when units == "MB": size / 1.0.megabyte
      when units == "GB": size / 1.0.gigabyte
      when units == "TB": size / 1.0.terabyte
    end
  end
  
end
