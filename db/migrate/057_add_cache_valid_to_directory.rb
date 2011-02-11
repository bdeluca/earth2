class AddCacheValidToDirectory < ActiveRecord::Migration
  def self.up
    add_column :directories, :cache_valid, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :directories, :cache_valid
  end
end
