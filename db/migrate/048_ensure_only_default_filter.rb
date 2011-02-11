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

# The previous migrations involving Filter didn't ensure that there would be a default filter of "*"
class EnsureOnlyDefaultFilter < ActiveRecord::Migration
  def self.up
    execute "DELETE FROM filters WHERE filename != '*' OR uid IS NOT NULL"
    # Delete cached sizes that aren't related to the default size
    execute "DELETE FROM cached_sizes WHERE filter_id != (SELECT id FROM filters WHERE filename = '*' AND uid IS NULL)"
  end

  def self.down
  end
end
