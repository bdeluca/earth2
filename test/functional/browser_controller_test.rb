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
require 'browser_controller'

# Re-raise errors caught by the controller.
class BrowserController; def rescue_action(e) raise e end; end

class BrowserControllerTest < Test::Unit::TestCase
  fixtures :servers, :directories, :files
  set_fixture_class :servers => Earth::Server, :directories => Earth::Directory, :files => Earth::File

  def setup
    @controller = BrowserController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_show_root
    get :show
    
    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:servers_and_bytes)
  end

  def test_show_root_flat
    get :flat
    
    assert_response :success
    assert_template 'flat'

    assert_not_nil assigns(:files)
  end

  def test_show_server
    get :show, :server => Earth::Server.this_hostname
    
    assert_response :success
    assert_template 'show'

    assert_nil(assigns(:directory))
    assert_equal(servers(:first), assigns(:server))
  end

  def test_show
    get :show, :server => Earth::Server.this_hostname, :path => "/foo"
    
    assert_response :success
    assert_template 'show'

    assert_equal(directories(:foo), assigns(:directory))
    assert_equal([[directories(:foo_bar), directories(:foo_bar).size.bytes]], assigns(:directories_and_bytes))
  end

  def test_show_with_server_and_path_as_csv
    @request.env['HTTP_ACCEPT'] = 'text/csv'
    get :show, {:server => Earth::Server.this_hostname, :path => "/foo/bar", :show_empty => 1}
    assert_response :success
    assert_equal(directories(:foo_bar), assigns(:directory))
  end
  
  def test_show_with_server_and_path
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :show, {:server => Earth::Server.this_hostname, :path => "/foo/bar", :show_empty => 1}
    
    assert_response :success
    assert_template 'show.rxml'
    
    assert_equal(directories(:foo_bar), assigns(:directory))
    
    # Just check for one the two files
    assert_tag :tag => "file",
      :attributes => {:name => "a"},
      :parent => {:tag => "directory", :attributes => {:path => "/foo/bar"}},
      :child => {:tag => "size_in_bytes", :content => files(:file3).bytes.to_s}
    # There should only be one directory (in this case)
    assert_tag :tag => "directory",
      :attributes => {:name => "twiddle"},
      :parent => {:tag => "directory", :attributes => {:path => "/foo/bar"}},
      :child => {:tag => "size_in_bytes", :content => directories(:foo_bar_twiddle).size.bytes.to_s}
  end
  
  def test_index
    get :index
    assert_response :redirect
  end

#  def test_show_with_no_server
#    get :show
#
#    assert_response :success
#    assert_template 'show'
#
#    assert_not_nil assigns(:servers_and_sizes)
#  end
  
  def test_routing
    assert_routing("/browser/show", :controller => "browser", :action => "show")
    assert_routing("/browser/show/foo.rsp.com.au", :controller => "browser", :action => "show", :server => "foo.rsp.com.au")
    assert_routing("/browser/show/foo-bar.rsp.com.au", :controller => "browser", :action => "show", :server => "foo-bar.rsp.com.au")
    assert_routing("/browser/show/foo-bar.rsp-foo.com.au", :controller => "browser", :action => "show", :server => "foo-bar.rsp-foo.com.au")
    assert_routing("/browser/show/foo", :controller => "browser", :action => "show", :server => "foo")
    assert_routing("/browser/show/foo-bar", :controller => "browser", :action => "show", :server => "foo-bar")
    assert_routing("/browser/show/foo.rsp.com.au/blah/foo/bar",
      :controller => "browser", :action => "show", :server => "foo.rsp.com.au", :path => ["", "blah", "foo", "bar"])
    assert_routing("/browser/show/foo/blah/foo/bar",
      :controller => "browser", :action => "show", :server => "foo", :path => ["", "blah", "foo", "bar"])
    assert_routing("/browser/show.xml/foo.rsp.com.au/blah/foo/bar",
      :controller => "browser", :action => "show", :server => "foo.rsp.com.au", :path => ["", "blah", "foo", "bar"], :format => "xml")

    assert_routing("/graph", :controller => "graph", :action => "index")
    assert_routing("/graph/foo.rsp.com.au", :controller => "graph", :action => "index", :server => "foo.rsp.com.au")
    assert_routing("/graph/foo-bar.rsp.com.au", :controller => "graph", :action => "index", :server => "foo-bar.rsp.com.au")
    assert_routing("/graph/foo-bar.rsp-foo.com.au", :controller => "graph", :action => "index", :server => "foo-bar.rsp-foo.com.au")

    assert_routing("/graph/show", :controller => "graph", :action => "show")
    assert_routing("/graph/show/foo.rsp.com.au", :controller => "graph", :action => "show", :server => "foo.rsp.com.au")
    assert_routing("/graph/show/foo-bar.rsp.com.au", :controller => "graph", :action => "show", :server => "foo-bar.rsp.com.au")
    assert_routing("/graph/show/foo-bar.rsp-foo.com.au", :controller => "graph", :action => "show", :server => "foo-bar.rsp-foo.com.au")
  end
end
