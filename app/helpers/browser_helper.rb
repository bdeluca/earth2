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

module BrowserHelper

  LINKED_FILE_PATH_SHOW_PARENT_LINK = false
  LINKED_FILE_PATH_SHOW_CURRENT     = false

  def inverse_order(order)
    if order == "asc"
      "desc"
    else
      "asc"
    end
  end

  def sortable_table_header(name, param = nil)    
    param = name.downcase if param.nil?
    
    parameter_map = {}
    indicator = ""

    sort1 = (params[:sort1] || @default_sort_by[0])
    sort_order = [
      [ param, (sort1 == param ? (inverse_order(params[:order1])) : @default_order[param]) ]
    ]

    1.upto(@max_num_sort_criteria - 1) do |sort_index|
      sort_param = (params["sort#{sort_index}".to_sym] || @default_sort_by[sort_index - 1])
      if sort_param != param
        sort_order << [ sort_param, params["order#{sort_index}".to_sym] || @default_order[sort_param] ]
      end
    end

    1.upto(@max_num_sort_criteria) do |sort_index|
      if sort_index <= sort_order.size
        parameter_map["sort#{sort_index}".to_sym] = sort_order[sort_index-1][0]
        parameter_map["order#{sort_index}".to_sym] = sort_order[sort_index-1][1]
      end

      if (params["sort#{sort_index}".to_sym] || @default_sort_by[sort_index - 1]) == param
        order = (params["order#{sort_index}".to_sym] || @default_order[params["sort#{sort_index}".to_sym]])
        indicator = " <img src=\"/images/sort#{sort_index}-#{order}.png\" width=\"9\" height=\"8\"/>"
      end
    end

    parameter_map[:page] = nil
    url = url_for(:overwrite_params => parameter_map)

    "<a href=\"#{url}\" class=\"sortable-column\">#{name}#{indicator}</a>"
  end

  def linked_file_path(file)
    html = ""
    if not @server
      # On root level
      html = "root::" if LINKED_FILE_PATH_SHOW_CURRENT
      html += link_to(file.directory.server.name, 
                      :overwrite_params => {:page => nil, 
                                            :server => file.directory.server.name, 
                                            :path => nil})
      html += ":"
    elsif @server and not @directory
      # On server level
      if LINKED_FILE_PATH_SHOW_PARENT_LINK
        html = link_to("root", 
                       :overwrite_params => {:page => nil, 
                                             :path => nil, 
                                             :server => nil})
        html += "::"
      end
      if LINKED_FILE_PATH_SHOW_CURRENT
        html += h(@server.name)
        html += ":"
      end
    elsif @directory and not @directory.parent_id
      # On top directory level
      if LINKED_FILE_PATH_SHOW_PARENT_LINK
        html = link_to("..", 
                       :overwrite_params => {:page => nil, 
                                             :path => nil})
        html += ":"
      end
    else
      # On deeper directory level
      if LINKED_FILE_PATH_SHOW_PARENT_LINK
        html = link_to("..", 
                       :overwrite_params => {:page => nil, 
                                             :path => @directory.parent.path})
      end
    end
    self_and_ancestors_up_to(file.directory, @directory).reverse.each do |parent| 
      if parent == @directory
        if LINKED_FILE_PATH_SHOW_CURRENT
          html += h(parent.name.gsub(/ /, "&nbsp;"))
          html += "/<wbr/>"
        end
      else 
        html += link_to(parent.name.gsub(/ /, "&nbsp;"), 
                        :overwrite_params => {:page => nil, 
                                              :server => file.directory.server.name,  
                                              :path => parent.path})
        html += "/<wbr/>"
      end
    end
    html
  end
end
