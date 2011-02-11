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

class RemoveFilterTable < ActiveRecord::Migration
  def self.up
    remove_index :cached_sizes, [:directory_id, :filter_id]
    remove_column :cached_sizes, :filter_id
    drop_table :filters
  end

  def self.down
    create_table :filters, :force => true do |t|
      t.column :filename, :string,  :null => false
      t.column :uid,      :integer
    end
    add_column :cached_sizes, :filter_id, :integer, :null => false
    add_index :cached_sizes, [:directory_id, :filter_id], :unique
  end
end
