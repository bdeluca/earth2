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

class CreatePluginsTables < ActiveRecord::Migration
  def self.up

    create_table :plugin_descriptors do |t|
      t.column :name, :string, :null => false, :limit => 64
      t.column :version, :integer, :null => false
      t.column :code, :binary,  :null => false
      t.column :sha1_signature, :binary,  :null => false
    end
    execute "ALTER TABLE plugin_descriptors ADD CONSTRAINT plugin_descriptors_unique_name UNIQUE (name)"

    create_table :metadata_attributes do |t|
      t.column :name, :string, :null => false
      t.column :plugin_descriptor_id, :integer,  :null => false
      t.foreign_key :plugin_descriptor_id, :plugin_descriptors, :id, { :on_delete => :cascade, :name => "metadata_attribute_plugin_descriptor_id_fk" }
    end
    execute "ALTER TABLE metadata_attributes ADD CONSTRAINT metadata_attributes_name_plugin_id_revision UNIQUE (name, plugin_descriptor_id)"

    create_table :metadata_strings do |t|
      t.column :metadata_attribute_id, :integer,  :null => false
      t.column :value, :string, :null => false
      t.foreign_key :metadata_attribute_id, :metadata_attributes, :id, { :on_delete => :cascade, :name => "metadata_string_attribute_id_fk" }
    end

    create_table :file_metadata_strings, :id => false do |t|
      t.column :file_id, :integer,  :null => false
      t.foreign_key :file_id, :files, :id, { :on_delete => :cascade, :name => "file_metadata_file_id_fk" }
      t.column :metadata_string_id, :integer,  :null => true
      t.foreign_key :metadata_string_id, :metadata_strings, :id, { :on_delete => :cascade, :name => "file_metadata_string_id_fk" }
    end
  end

  def self.down
    drop_table :file_metadata_strings
    drop_table :metadata_strings
    drop_table :metadata_attributes
    drop_table :plugin_descriptors
  end
end
