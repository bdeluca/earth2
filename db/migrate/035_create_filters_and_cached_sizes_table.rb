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

class CreateFiltersAndCachedSizesTable < ActiveRecord::Migration
  def self.up
    create_table :filters do |t|
      t.column :filename, :string, :null => false
      t.column :uid, :integer
    end
    add_index :filters, [:filename, :uid]

    execute "INSERT INTO filters(filename, uid) VALUES ('*', NULL)"
    execute "INSERT INTO filters(filename, uid) VALUES ('*.zip', NULL)"
    execute "INSERT INTO filters(filename, uid) VALUES ('*.jar', NULL)"
    execute "INSERT INTO filters(filename, uid) VALUES ('*.gif', NULL)"
    
    create_table :cached_sizes do |t|
      t.column :directory_id, :integer, :null => false
      t.column :filter_id, :integer, :null => false
      t.column :recursive_size, :integer, :limit => 21, :default => 0, :null => false     # allow for a zettabyte
      t.column :recursive_blocks, :integer, :limit => 19, :default => 0, :null => false   # allow for a zettabyte
      t.foreign_key :directory_id, :directories, :id, { :on_delete => :cascade, :name => "cached_sizes_directories_id_fk"  }
      t.foreign_key :filter_id, :filters, :id, { :on_delete => :cascade, :name => "cached_sizes_filters_id_fk" }
    end
    add_index :cached_sizes, :directory_id
    add_index :cached_sizes, [:directory_id, :filter_id]
  end
  
  def self.down
    drop_table :cached_sizes
    drop_table :filters
  end  
end

