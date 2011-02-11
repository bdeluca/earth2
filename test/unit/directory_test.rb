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

class DirectoryTest < Test::Unit::TestCase
  fixtures :servers, :directories, :files
  set_fixture_class :servers => Earth::Server, :directories => Earth::Directory, :files => Earth::File

  def test_server
    assert_equal(servers(:first), directories(:foo_bar_twiddle).server)
  end
  
  def test_find_subdirectories_at_level
    assert_equal([directories(:foo_bar_twiddle)], directories(:foo).find_subdirectories_at_level(3))
    assert_equal([], directories(:bar).find_subdirectories_at_level(2))
  end
  
  def test_find_by_path
    assert_equal(directories(:foo), Earth::Directory.find_by_path("/foo"))
    assert_equal(directories(:foo_bar), Earth::Directory.find_by_path("/foo/bar"))
    assert_equal(directories(:foo_bar_twiddle), Earth::Directory.find_by_path("/foo/bar/twiddle"))
    assert_equal(directories(:bar), Earth::Directory.find_by_path("/bar"))
    assert_nil(Earth::Directory.find_by_path("/foo/bar/boo"))
  end
  
  def test_path
    assert_equal("/foo", directories(:foo).path)
    assert_equal("/foo/bar", directories(:foo_bar).path)
    assert_equal("/foo/bar/twiddle", directories(:foo_bar_twiddle).path)
  end
  
  def test_path_set_directly
    dir = Earth::Directory.create(:name => "blah", :server_id => directories(:foo).server_id, :path => "/foo/blah")
    assert_equal("/foo/blah", dir.path)
  end
  
  def test_path_on_create
    dir = directories(:foo_bar).children.create(:name => "another", :path => "/foo/bar/another", :server_id => directories(:foo_bar).server_id)
    assert_equal("/foo/bar/another", dir.path)
    assert_equal(directories(:foo_bar), dir.parent)
    dir = Earth::Server.this_server.directories.create(:name => "/a/root/directory", :path => "/a/root/directory")
    assert_equal("/a/root/directory", dir.path)
  end

  #commented out - tests implementation details  
  # Tests an alternative interface to "move_to_child_of"
  def test_set_parent 
    assert_equal(2, directories(:foo_bar).lft)
    assert_equal(9, directories(:foo_bar).rgt)
    dir = Earth::Directory.new(:name => "another", :path => "/foo/bar/another", :server_id => directories(:foo_bar).server_id)
    dir.parent = directories(:foo_bar)
    dir.save
    assert_equal(directories(:foo_bar).id, dir.parent_id)
    assert_equal("/foo/bar/another", dir.path)
    dir.reload
    assert_equal(9, dir.lft)
    assert_equal(10, dir.rgt)
    directories(:foo_bar).reload
    assert_equal(2, directories(:foo_bar).lft)
    assert_equal(11, directories(:foo_bar).rgt)
  end

  def test_set_parent_on_create_disallowed
    assert_raises(RuntimeError) { Earth::Directory.create(:name => "another", :parent => directories(:foo_bar)) }
  end
  
  def test_name
    assert_equal("/foo", directories(:foo).name)
    assert_equal("bar", directories(:foo_bar).name)
    assert_equal("twiddle", directories(:foo_bar_twiddle).name)
  end
  
  def test_stat
    # Getting a File::Stat from a "random" file
    stat = File.lstat(File.dirname(__FILE__) + '/../test_helper.rb')
    directories(:foo).stat = stat
    assert_equal(stat.mtime, directories(:foo).modified)
    # And we should be able to read back as a stat object
    assert_equal(stat.mtime, directories(:foo).stat.mtime)
    # And we should be able to directly compare the stats even though they are different kinds of object
    assert_kind_of(File::Stat, stat)
    assert_kind_of(Earth::Directory::Stat, directories(:foo).stat)
    assert_equal(stat, directories(:foo).stat)
    assert_equal(directories(:foo).stat, stat)
  end
  
  def test_size
    assert_equal(files(:file1).bytes + files(:file2).bytes + files(:file3).bytes + files(:file4).bytes + files(:zip_file1).bytes + files(:zip_file2).bytes,
      directories(:foo).size.bytes)
    assert_equal(files(:file3).bytes + files(:file4).bytes + files(:zip_file1).bytes + files(:zip_file2).bytes,
      directories(:foo_bar).size.bytes)
  end
  
  # Doing this to double-check my understanding of caching with associations in ActiveRecord
  # assert_no_queries was taken from ActiveRecord tests
  def test_association_caching
    file1 = files(:file1)
    file2 = files(:file2)
    foo = directories(:foo)
    
    assert_equal([file1, file2], foo.files)
    assert_number_of_sql_queries(0) {assert_equal([file1, file2], foo.files)}
    # Test that creating on an association like this means that the cached association gets updated too
    file3 = foo.files.create(:name => "c", :bytes => 3)
    assert_number_of_sql_queries(0) {assert_equal([file1, file2, file3], foo.files)}
    foo.files.delete(file2)
    assert_number_of_sql_queries(0) {assert_equal([file1, file3], foo.files)}
  end
  
  def test_child_create
    dir = directories(:foo).child_create(:name => "blah", :path => "/foo/blah", :server_id => directories(:foo).server_id)
    assert_equal("blah", dir.name)
    assert_equal("/foo/blah", dir.path)
    assert_equal(directories(:foo), dir.parent)
    assert_equal(1, dir.server_id)
    assert_equal([directories(:foo_bar), dir], directories(:foo).children)
  end

  def test_children
    foo = directories(:foo)
    foo_bar = directories(:foo_bar)
    
    assert_equal([foo_bar], foo.children)
    assert_number_of_sql_queries(0) {assert_equal([foo_bar], foo.children)}
    
    foo_fiddle = foo.child_create(:name => "fiddle", :path => "/foo/fiddle", :server_id => foo.server_id)
    assert_number_of_sql_queries(0) {assert_equal([foo_bar, foo_fiddle], foo.children)}
    # Force a reload of children and check that the values are correct too
    assert_number_of_sql_queries(1) {assert_equal([foo_bar, foo_fiddle], foo.children(true))}
    foo.child_delete(foo_bar)
    assert_number_of_sql_queries(0) {assert_equal([foo_fiddle], foo.children)}
    assert_number_of_sql_queries(1) {assert_equal([foo_fiddle], foo.children(true))}
  end

   def test_no_children_reload
     foo = directories(:foo)
     #assert_no_queries{foo.add_child_internal(Directory.new(:name => "foobar", :server_id => foo.server_id))}
     #assert_no_queries{foo.list_children}
   end

   def test_load_all_children
     foo = directories(:foo)
     foo_bar = directories(:foo_bar)
     foo_bar_twiddle = directories(:foo_bar_twiddle)
     foo_bar_twiddle_frob = directories(:foo_bar_twiddle_frob)
     foo_bar_twiddle_frob_baz = directories(:foo_bar_twiddle_frob_baz)

     assert_number_of_sql_queries(1) {foo.load_all_children}
     assert_number_of_sql_queries(0) {assert_equal([foo_bar], foo.children)}
     assert_number_of_sql_queries(0) {assert_equal([foo_bar_twiddle], foo.children[0].children)}
     assert_number_of_sql_queries(0) {assert_equal([foo_bar_twiddle_frob], foo.children[0].children[0].children)}
     assert_number_of_sql_queries(0) {assert_equal([foo_bar_twiddle_frob_baz], foo.children[0].children[0].children[0].children)}
     assert_number_of_sql_queries(0) {assert_equal([], foo.children[0].children[0].children[0].children[0].children)}
   end
  
  def test_each
    a = []
    directories(:foo).each {|x| a << x.path}
    # We should move from the root to the leaves
    assert_equal(["/foo", "/foo/bar", "/foo/bar/twiddle", "/foo/bar/twiddle/frob", "/foo/bar/twiddle/frob/baz"], a)
  end
  
  def test_update
    foo = directories(:foo)
    assert_equal(1, foo.lft)
    assert_equal(10, foo.rgt)
    foo_bar = directories(:foo_bar)
    # This will update the lft and rgt values of foo in the database (but not in the loaded object)
    assert_equal(2, foo_bar.lft)
    assert_equal(9, foo_bar.rgt)
    foo_bar.child_create(:name => "wibble", :path => "/foo/bar/wibble", :server_id => foo_bar.server_id)
    foo_bar.reload
    assert_equal(2, foo_bar.lft)
    assert_equal(11, foo_bar.rgt)
    assert_equal(1, foo.lft)
    assert_equal(10, foo.rgt)
    foo.name = 'name'
    foo.modified = Time.at(0).utc
    foo.update
    
    foo.reload
    assert_equal('name', foo.name)
    assert_equal(Time.at(0), foo.modified)
    assert_equal(1, foo.lft)
    assert_equal(12, foo.rgt)
  end
  
  # Test that deleting a directory (which also deletes all directories below it) also deletes
  # all associated files
  def test_destroy
    directories(:foo).destroy
    assert_equal([directories(:fizzle), directories(:bar)], Earth::Directory.find(:all))
    assert_equal([files(:file5),
                  files(:large_file1),
                  files(:large_file2),
                  files(:large_file3)], Earth::File.find(:all))
  end
  
  def test_recursive_file_count
    assert_equal(6, directories(:foo).size.count)
    assert_equal(4, directories(:foo_bar).size.count)
    assert_equal(1, directories(:foo_bar_twiddle).size.count)
    assert_equal(0, directories(:bar).size.count)
  end
  
  def test_has_files
    assert(directories(:foo).has_files?)
    assert(directories(:foo_bar).has_files?)
    assert(directories(:foo_bar_twiddle).has_files?)
    assert(directories(:foo_bar_twiddle_frob).has_files?)
    assert(directories(:foo_bar_twiddle_frob_baz).has_files?)
    assert(!directories(:bar).has_files?)
    assert(directories(:fizzle).has_files?)
  end
  
  def test_not_caching_files
    directory = directories(:foo)
    #assert_queries(1) {p directory.files}
    assert(!directory.files.loaded?)
    assert_number_of_sql_queries(1) {directory.files.to_ary}
    assert(directory.files.loaded?)
    assert_number_of_sql_queries(0) {directory.files.to_ary}
    # Stops the caching of the files (until they are reloaded)
    assert_number_of_sql_queries(0) {directory.files.reset}
    assert(!directory.files.loaded?)
    assert_number_of_sql_queries(1) {directory.files.to_ary}
  end
  
end

class TransactionalDirectoryTest < Test::Unit::TestCase
  fixtures :servers, :directories, :files
  set_fixture_class :servers => Earth::Server, :directories => Earth::Directory, :files => Earth::File
  self.use_transactional_fixtures = false
  
  def setup
    @allow_concurrency = ActiveRecord::Base.allow_concurrency
    ActiveRecord::Base.allow_concurrency = true
  end
  
  def teardown
    ActiveRecord::Base.allow_concurrency = @allow_concurrency
  end
  
  # Test that when we are calculating the size of a directory and the daemon is updating
  # the DB at the same time, that we get consistent results from the Directory.find to the
  # Directory.size
  def test_concurrency
    reader = Thread.new do
      10.times do
        Earth::Directory.transaction do
          foo_bar = Earth::Directory.find(2) # => /foo/bar
          sleep(0.01)
          assert_equal(31, foo_bar.size.bytes)
        end
      end
    end
    writer = Thread.new do
      (1..10).each { |i|
        d = Earth::Directory.find(1)
        d.child_create(:name => "bruno#{i}", :server_id => d.server_id) # => /foo/bruno#{counter}
        }
      end

      reader.join
      writer.join
  end
  
end
