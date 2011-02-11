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

class ServersController < ApplicationController
  # GET /servers
  # GET /servers.xml
  def index
    Earth::File::with_filter do
      @servers = Earth::Server.find(:all)

      respond_to do |format|
        format.html # index.rhtml
        format.xml  { render :xml => @servers.to_xml }
      end
    end
  end

  # GET /servers/1
  # GET /servers/1.xml
  def show
    Earth::File::with_filter do
      @server = Earth::Server.find_by_name(params[:server])

      respond_to do |format|
        format.html # show.rhtml
        format.xml  { render :xml => @server.to_xml }
      end
    end
  end

  # GET /servers/1;edit
  def edit
    Earth::File::with_filter do
      @server = Earth::Server.find_by_name(params[:server])
    end
  end

  # PUT /servers/1
  # PUT /servers/1.xml
  def update
    @server = Earth::Server.find(params[:id])

    respond_to do |format|
      if @server.update_attributes(params[:server])
        flash[:notice] = 'Server was successfully updated.'
        format.html { redirect_to :action => "show", :params => { :server => @server.name } }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @server.errors.to_xml }
      end
    end
  end
end
