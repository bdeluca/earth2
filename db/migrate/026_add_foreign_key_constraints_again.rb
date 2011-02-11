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

class AddForeignKeyConstraintsAgain < ActiveRecord::Migration
  def self.up
    add_foreign_key :files, :directory_id, :directories, :id, { :name => "files_directories_id_fk" }
    add_foreign_key :directories, :server_id, :servers, :id, { :name => "directories_servers_id_fk" }
  end

  def self.down
    remove_foreign_key :files, :files_directories_id_fk
    remove_foreign_key :directories, :directories_servers_id_fk
  end
end
