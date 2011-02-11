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

require File.dirname(__FILE__) + '/../../test_helper'

class ApplicationHelperTest < HelperTestCase

  include ApplicationHelper

  def test_human_units_of
    assert_equal("Bytes", ApplicationHelper.human_units_of(500))
    assert_equal("KB", ApplicationHelper.human_units_of(5 * 1024))
    assert_equal("MB", ApplicationHelper.human_units_of(5 * 1024 * 1024))
    assert_equal("GB", ApplicationHelper.human_units_of(5 * 1024 * 1024 * 1024))
    assert_equal("TB", ApplicationHelper.human_units_of(5 * 1024 * 1024 * 1024 * 1024))
    assert_equal("TB", ApplicationHelper.human_units_of(5 * 1024 * 1024 * 1024 * 1024 * 1024))
  end
  
  def test_human_size_in
    assert_equal("500", ApplicationHelper.human_size_in("Bytes", 500))
    assert_equal("0.5", ApplicationHelper.human_size_in("KB",    500))
    assert_equal("> 0", ApplicationHelper.human_size_in("MB",    500))

    assert_equal("5120", ApplicationHelper.human_size_in("Bytes", 5 * 1024))
    assert_equal("5",    ApplicationHelper.human_size_in("KB",    5 * 1024))
    assert_equal("> 0",  ApplicationHelper.human_size_in("MB",    5 * 1024))

    assert_equal("5242880", ApplicationHelper.human_size_in("Bytes", 5 * 1024 * 1024))
    assert_equal("5120",    ApplicationHelper.human_size_in("KB",    5 * 1024 * 1024))
    assert_equal("5",       ApplicationHelper.human_size_in("MB",    5 * 1024 * 1024))
    assert_equal("5",       ApplicationHelper.human_size_in("GB",    5 * 1024 * 1024 * 1024))
    assert_equal("5",       ApplicationHelper.human_size_in("TB",    5 * 1024 * 1024 * 1024 * 1024))
  end
  
  def test_human_size_in_zero
    assert_equal("0", ApplicationHelper.human_size_in("Bytes", 0))
    assert_equal("0", ApplicationHelper.human_size_in("KB", 0))
    assert_equal("0", ApplicationHelper.human_size_in("MB", 0))
    
    assert_equal("1", ApplicationHelper.human_size_in("Bytes", 1))
    assert_equal("> 0", ApplicationHelper.human_size_in("KB", 1))
    assert_equal("> 0", ApplicationHelper.human_size_in("MB", 1))
  end

  def test_bar
    assert(/width: 10%/.match(bar(1, 10, :class => "bar")))
    assert(/width: 100%/.match(bar(1, 0, :class => "bar")))
  end
end
