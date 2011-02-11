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
require 'graph_controller'

# Re-raise errors caught by the controller.
class GraphController; def rescue_action(e) raise e end; end

class GraphControllerTest < Test::Unit::TestCase
  fixtures :servers, :directories, :files
  set_fixture_class :servers => Earth::Server, :directories => Earth::Directory, :files => Earth::File

  def setup
    @controller = GraphController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index_root
    get :index

    assert_response :success
    assert_template 'index'

    #assert_equal(directories(:foo), assigns(:directory))
    #assert_equal([[directories(:foo_bar), directories(:foo_bar).size]], assigns(:directories_and_size))
    
  end

  def test_index_subdirectory_unfiltered
    get :index, :server => Earth::Server.this_hostname, :path => "/foo/bar/twiddle/frob"

    assert_response :success
    assert_template 'index'

    #assert_equal(directories(:foo), assigns(:directory))
    #assert_equal([[directories(:foo_bar), directories(:foo_bar).size]], assigns(:directories_and_size))
    
  end

  def test_show_root
    get :show

    assert_response :success
    assert_template 'servers.rxml'

    #assert_equal(directories(:foo), assigns(:directory))
    #assert_equal([[directories(:foo_bar), directories(:foo_bar).size]], assigns(:directories_and_size))
    
  end

  def test_show_server
    get :show, :server => Earth::Server.this_hostname

    assert_response :success
    assert_template 'directory.rxml'

    #assert_equal(directories(:foo), assigns(:directory))
    #assert_equal([[directories(:foo_bar), directories(:foo_bar).size]], assigns(:directories_and_size))
    
  end


  def test_show_yet_another_server
    get :show, :server => servers(:yet_another).name

    assert_response :success
    assert_template 'directory.rxml'

    #assert_equal(directories(:foo), assigns(:directory))
    #assert_equal([[directories(:foo_bar), directories(:foo_bar).size]], assigns(:directories_and_size))
    
  end

  def test_show_directory_unfiltered
    get :show, :server => Earth::Server.this_hostname, :path => "/foo"

    assert_response :success
    assert_template 'directory.rxml'

    #assert_equal(directories(:foo), assigns(:directory))
    #assert_equal([[directories(:foo_bar), directories(:foo_bar).size]], assigns(:directories_and_size))
    
  end

  def test_show_subdirectory_unfiltered
    get :show, :server => Earth::Server.this_hostname, :path => "/foo/bar/twiddle/frob"

    assert_response :success
    assert_template 'directory.rxml'

    #assert_equal(directories(:foo), assigns(:directory))
    #assert_equal([[directories(:foo_bar), directories(:foo_bar).size]], assigns(:directories_and_size))
    
  end

  def test_show_directory_filter_filename
    get :show, :server => Earth::Server.this_hostname, :path => "/foo", :filter_filename => "*.zip"

    assert_response :success
    assert_template 'directory.rxml'

    #assert_equal(directories(:foo), assigns(:directory))
    #assert_equal([[directories(:foo_bar), directories(:foo_bar).size]], assigns(:directories_and_size))
    
  end

end
