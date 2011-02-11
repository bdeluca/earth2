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

# Move the size cache from cached_sizes to directories table
class MoveCacheToDirectory < ActiveRecord::Migration
  def self.up
    # allow for a zettabyte
    add_column :directories, :bytes, :integer, :limit => 21, :default => 0, :null => false
    # allow for a zettabyte
    add_column :directories, :blocks, :integer, :limit => 19, :default => 0, :null => false
    add_column :directories, :count, :integer, :null => false, :default => 0
    execute "UPDATE directories SET bytes=(SELECT bytes FROM cached_sizes where directory_id=directories.id), blocks=(SELECT blocks FROM cached_sizes where directory_id=directories.id), count=(SELECT count FROM cached_sizes where directory_id=directories.id)"
  end
  def self.down
    remove_column :directories, :count
    remove_column :directories, :blocks
    remove_column :directories, :bytes
  end
end
