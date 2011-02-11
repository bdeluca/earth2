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

require File.dirname(__FILE__) + '/../test_helper'
require 'servers_controller'

# Re-raise errors caught by the controller.
class ServersController; def rescue_action(e) raise e end; end

class ServersControllerTest < Test::Unit::TestCase
  fixtures :servers, :directories, :files
  set_fixture_class :servers => Earth::Server, :directories => Earth::Directory, :files => Earth::File

  def setup
    @controller = ServersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:servers)
  end

  def test_should_show_server
    get :show, :server => Earth::Server.this_hostname
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :server => Earth::Server.this_hostname
    assert_response :success
  end
  
  def test_should_update_server
    put :update, :id => 1, :server => { }
    assert_redirected_to :controller => "servers", :action => "show", :params => { :server => Earth::Server.this_hostname }
  end
end
