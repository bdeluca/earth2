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

# Drop the cached_sizes table
class DropCachedSizes < ActiveRecord::Migration
  def self.up
    drop_table :cached_sizes
  end
  def self.down
    create_table :cached_sizes do |t|
      t.column :directory_id, :integer, :null => false
      t.column :bytes, :integer, :limit => 21, :default => 0, :null => false     # allow for a zettabyte
      t.column :blocks, :integer, :limit => 19, :default => 0, :null => false   # allow for a zettabyte
      t.column :count, :integer, :default => 0, :null => false
      t.foreign_key :directory_id, :directories, :id, { :on_delete => :cascade, :name => "cached_sizes_directories_id_fk"  }
    execute "UPDATE cached_sizes SET bytes=(SELECT bytes FROM directories where id=cached_sizes.directory_id), blocks=(SELECT blocks FROM directories where id=cached_sizes.directory_id), count=(SELECT count FROM directories where id=cached_sizes.directory_id)"
    end
    
  end
end


