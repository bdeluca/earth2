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

require File.dirname(__FILE__) + '/abstract_unit'
#require File.dirname(__FILE__) + '/fixtures/mixin'
require 'pp'

class CategoryTest < Test::Unit::TestCase
  fixtures :categories

  def assert_nested_set_order(node, left=nil)
    parent = node[0]
    node = node[1, node.length]
    parent.reload
    if left.nil?
      left = parent.lft
    end
    assert_equal(left, parent.lft, "left of node #{parent.name} assumed to be #{left} but is #{parent.lft}")
    child_left = left + 1
    child_right = child_left
    if node
      node.each do |child|
        child_right = assert_nested_set_order(child, child_left) + 1
        child_left = child_right
      end
    end
    right = child_right
    assert_equal(right, parent.rgt, "right of node #{parent.name} assumed to be #{right} but is #{parent.rgt}")
    right
  end

  def test_create_tree_1
    root      = Category.create("name" => "root")
    child1    = root.children.create("name" => "child1")
    child1a   = child1.children.create("name" => "child1a")
    child2    = root.children.create("name" => "child2")
    assert_nested_set_order([root, [child1, [child1a]], [child2]])

    root.reload

    assert_equal(1, root.lft)
    assert_equal(8, root.rgt)
    assert_equal(3, root.children_count)

    assert_equal(1, child1.children_count)
    assert_equal(0, child1a.children_count)
    assert_equal(0, child2.children_count)
  end

  def test_create_tree_2
    root      = Category.create("name" => "root")
    child1    = root.children.create("name" => "child1")
    child1a   = child1.children.create("name" => "child1a")
    root.reload
    child2    = root.children.create("name" => "child2")
    assert_nested_set_order([root, [child1, [child1a]], [child2]])

    child1.reload
    child1b   = child1.children.create("name" => "child1b")
    assert_nested_set_order([root, [child1, [child1a], [child1b]], [child2]])
  end

  def test_insert_1
    root      = Category.new("name" => "root")
    child1    = root.children.build("name" => "child1")
    child1a   = child1.children.build("name" => "child1a")
    root.save
    assert_not_nil root.id
    assert_not_nil child1.id
    assert_not_nil child1a.id

    assert_nested_set_order([root, [child1, [child1a]]])

    child1b  = child1.children.build("name" => "child1b")
    child1b.save
    assert_not_nil child1b.id

    assert_nested_set_order([root, [child1, [child1a], [child1b]]])
  end

  def test_insert_2
    root      = Category.new("name" => "root")
    child1    = root.children.build("name" => "child1")
    child1a   = child1.children.build("name" => "child1a")
    root.save

    assert_nested_set_order([root, [child1, [child1a]]])

    child1b  = child1.children.build("name" => "child1b")
    root.save

    assert_nested_set_order([root, [child1, [child1a], [child1b]]])
  end

  def test_insert_3
    root      = Category.new("name" => "root")
    child1    = root.children.build("name" => "child1")
    child1a   = child1.children.build("name" => "child1a")
    root.save

    assert_nested_set_order([root, [child1, [child1a]]])

    child1b  = Category.new("name" => "child1b")
    child1.add_child(child1b)

    assert_nested_set_order([root, [child1, [child1a], [child1b]]])
  end


  def test_insert_3a
    root      = Category.new("name" => "root")
    child1    = root.children.build("name" => "child1")
    child1a   = child1.children.build("name" => "child1a")
    root.save

    assert_nested_set_order([root, [child1, [child1a]]])

    child1b  = Category.new("name" => "child1b")
    child1b.parent = child1
    child1b.save()

    assert_nested_set_order([root, [child1, [child1a], [child1b]]])
  end

  def test_multi_tree
    root1      = Category.create("name" => "root1")
    child1     = root1.children.create("name" => "child1")
    root2      = Category.create("name" => "root2")
    child2     = root2.children.create("name" => "child2")
    assert_nested_set_order([root1, [child1]])
    assert_nested_set_order([root2, [child2]])
    root1.reload
    root2.reload
    assert(root2.lft == root1.rgt + 1)
  end

  def test_insert_3b
    root      = Category.new("name" => "root")
    child1    = root.children.build("name" => "child1")
    child1a   = child1.children.build("name" => "child1a")
    assert_equal(2, root.children_count)
    root.save

    assert_nested_set_order([root, [child1, [child1a]]])

    child1b  = Category.new("name" => "child1b_xx")
    child1b.parent = child1
    root.save()

    assert_nested_set_order([root, [child1, [child1a], [child1b]]])
  end

  def test_build_in_existing_tree
    root      = Category.create("name" => "root")
    child1    = root.children.create("name" => "child1")
    child2    = root.children.create("name" => "child2")
    child1a   = child1.children.create("name" => "child1a")
    child1b   = child1.children.create("name" => "child1b")
    child2a   = child2.children.create("name" => "child2a")
    child2b   = child2.children.create("name" => "child2b")
    child3    = root.children.build("name" => "child3")
    child3a   = child3.children.build("name" => "child3a")
    child3b   = child3.children.build("name" => "child3b")

    child3.save

    assert_equal([child1, child2, child3], root.children)
    assert_equal([child1a, child1b], child1.children)
    assert_equal([child2a, child2b], child2.children)
    assert_equal([child3a, child3b], child3.children)

    assert_nested_set_order([root, [child1, [child1a], [child1b]], [child2, [child2a], [child2b]], [child3, [child3a], [child3b]]])
  end

  def test_build_in_existing_tree_2
    root      = Category.new("name" => "root")
    child1    = root.children.build("name" => "child1")
    child2    = root.children.build("name" => "child2")
    child1a   = child1.children.build("name" => "child1a")
    child1b   = child1.children.build("name" => "child1b")
    child2a   = child2.children.build("name" => "child2a")
    child2b   = child2.children.build("name" => "child2b")

    root.save

    child3    = root.children.build("name" => "child3")
    child3a   = child3.children.build("name" => "child3a")
    child3b   = child3.children.build("name" => "child3b")

    child3.save

    assert_equal([child1, child2, child3], root.children)
    assert_equal([child1a, child1b], child1.children)
    assert_equal([child2a, child2b], child2.children)
    assert_equal([child3a, child3b], child3.children)

    assert_nested_set_order([root, [child1, [child1a], [child1b]], [child2, [child2a], [child2b]], [child3, [child3a], [child3b]]])
  end

  def make_tree(node, parent, &block)
    category = yield(parent, node[0])
    #[ category ] + node[1..node.length].reverse.map { |child| make_tree(child, category, &block) }.reverse
    [ category ] + node[1..node.length].map { |child| make_tree(child, category, &block) }
  end
 
  def build_tree(node)
    tree = make_tree(node, nil) do |parent, name| 
      if parent.nil?
        Category.new("name" => name)
      else
        parent.children.build("name" => name)
      end
    end
    tree[0].save
    tree
  end
 
  def create_tree(node)
    make_tree(node, nil) do |parent, name| 
      if parent.nil?
        category = Category.new("name" => name)
        category.save
        category
      else
        parent.children.create("name" => name)
      end
    end
  end

  def test_insert_4
    names = ["root", ["child1", ["child1a"], ["child1b"]]]
    categories = build_tree(names)
    assert_nested_set_order(categories)
  end

  def destroy_in_tree(node, name, parent=nil)
    head = node[0]
    if head.name == name
      head.destroy
      nil
    else
      rest = node[1..node.length].map { |child| delete_from_tree(child, name, head) }.delete_if { |child| child.nil?}
      [ head ] + rest
    end
  end


  def delete_from_tree(node, name, parent=nil)
    head = node[0]
    if head.name == name
      if parent.nil?
        head.destroy
      else
        parent.children.delete(head)
      end
      nil
    else
      rest = node[1..node.length].map { |child| delete_from_tree(child, name, head) }.delete_if { |child| child.nil?}
      [ head ] + rest
    end
  end

  def test_insert_delete_5
    names = ["root", ["child1", ["child1a"], ["child1b"]]]
    categories = create_tree(names)
    assert_nested_set_order(categories)
    categories = destroy_in_tree(categories, "child1a")
    assert_nested_set_order(categories)
  end

  def test_insert_delete_6
    names = ["root", ["child1", ["child1a"], ["child1b"]]]
    categories = create_tree(names)
    assert_nested_set_order(categories)
    categories = delete_from_tree(categories, "child1a")
    assert_nested_set_order(categories)
  end


  def test_a
    names = ["root", ["child1", ["child1a"], ["child1b"], ["child1c"]]]
    categories = create_tree(names)
    categories[0].reload
    assert_nested_set_order(categories)
  end


  def test_delete_7
    names = ["root", ["child1", ["child1a"], ["child1b"]]]
    categories = create_tree(names)
    assert_nested_set_order(categories)
    categories = delete_from_tree(categories, "child1")
    assert_nested_set_order(categories)
  end


  def test_reorder_7
    root      = Category.new("name" => "root")
    child1    = root.children.build("name" => "child1")
    child1a   = child1.children.build("name" => "child1a")
    child1b   = child1.children.build("name" => "child1b")
    child2    = child1a.children.build("name" => "child2")
    root.save()

    assert_nested_set_order([root, [child1, [child1a, [child2]], [child1b]]])

    child2.parent = child1b
    root.save()

    assert_nested_set_order([root, [child1, [child1a], [child1b, [child2]]]])

  end

end
