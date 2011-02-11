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

class UserTest < Test::Unit::TestCase
  # TODO: Tests currently hardcoded for a specific user. Make them more general.

  def setup
    User.config.delete "ldap_server_name"
    User.reset_cache
  end
    
  def test_name
    user = User.new(3054)
    assert_equal("3054", user.name)
  end
  
  def test_no_ldap_configured
    user = User.new(100)
    assert_equal("100", user.name)
  end

  def test_find
    user = User.find(100)
    assert_equal(100, user.uid)
  end

  def test_find_by_name
    user = User.find_by_name("3054")
    assert_equal(3054, user.uid)
    assert_equal("3054", user.name)
  end

  def test_find_matching
    users = User.find_matching("ken")
    assert_equal(0, users.size)
  end
  
  def test_find_all
    users = User.find_all
    assert(users.empty?)
  end
  
  def test_expiring_hash
    hash = ExpiringHash.new(2.days)
    hash[10] = 1
    assert_equal(1, hash[10])
  end

  def test_expiring_hash2
    hash = ExpiringHash.new(1.seconds)
    hash[10] = 1
    sleep(2)
    assert_nil(hash[10])
  end
end
