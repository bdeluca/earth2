require File.dirname(__FILE__) + '/abstract_unit'
#require File.dirname(__FILE__) + '/fixtures/mixin'
require 'pp'

class MixinNestedSetTest < Test::Unit::TestCase
	fixtures :mixins
	
	##########################################
	# HIGH LEVEL TESTS
	##########################################
	def disabled_test_mixing_in_methods
	  ns = NestedSet.new
		assert(ns.respond_to?(:all_children)) # test a random method
		
		check_method_mixins(ns)
		check_deprecated_method_mixins(ns) 
		check_class_method_mixins(NestedSet)
	end
	
	def check_method_mixins(obj)
	  [:<=>, :all_children, :ancestors, :before_create, :before_destroy, :check_subtree, :child?, :children, 
	  :children_count, :full_set, :left_col_name, :level, :move_to_child_of, 
	  :move_to_left_of, :move_to_right_of, :parent, :parent_col_name, :right_col_name, 
	  :root, :root?, :roots, :self_and_ancestors, :self_and_siblings, :siblings].each { |symbol| assert(obj.respond_to?(symbol)) }
  end
  
  def check_deprecated_method_mixins(obj)
    [:add_child, :direct_children, :parent_column, :unknown?].each { |symbol| assert(obj.respond_to?(symbol)) }
  end
  
  def check_class_method_mixins(klass)
	  [:root, :roots, :check_all].each { |symbol| assert(klass.respond_to?(symbol)) }
  end
  
	def disabled_test_string_scope
	  ns = NestedSet.new
	  assert_equal("root_id IS NULL", ns.scope_condition)
		
	  ns = NestedSetWithStringScope.new
	  ns.root_id = 1
	  assert_equal("root_id = 1", ns.scope_condition)
	  ns.root_id = 42
	  assert_equal("root_id = 42", ns.scope_condition)
	  check_method_mixins ns
  end
  
  def disabled_test_symbol_scope
    ns = NestedSetWithSymbolScope.new
    ns.root_id = 1
    assert_equal("root_id = 1", ns.scope_condition)
    ns.root_id = 42
    assert_equal("root_id = 42", ns.scope_condition)
    check_method_mixins ns
  end
  
  def disabled_test_protected_attributes
    ns = NestedSet.new(:parent_id => 2, :lft => 3, :rgt => 2)
    [:parent_id, :lft, :rgt].each {|symbol| assert_equal(nil, ns.send(symbol))}
  end
    
  def disabled_test_really_protected_attributes
    ns = NestedSet.new
    assert_raise(ActiveRecord::ActiveRecordError) {ns.parent_id = 1}
    assert_raise(ActiveRecord::ActiveRecordError) {ns.lft = 1}
    assert_raise(ActiveRecord::ActiveRecordError) {ns.rgt = 1}
  end
  
  ##########################################
	# CLASS METHOD TESTS
	##########################################
  def disabled_test_class_root
    NestedSetWithStringScope.roots.each {|r| r.destroy unless r.id == 4001}
    assert_equal(NestedSetWithStringScope.find(4001), NestedSetWithStringScope.root)
    NestedSetWithStringScope.find(4001).destroy
    assert_equal(nil, NestedSetWithStringScope.root)
    ns = NestedSetWithStringScope.create(:root_id => 2)
    assert_equal(ns, NestedSetWithStringScope.root)
  end
  
  def disabled_test_class_root_again
    NestedSetWithStringScope.roots.each {|r| r.destroy unless r.id == 101}
    assert_equal(NestedSetWithStringScope.find(101), NestedSetWithStringScope.root)
  end
  
  def disabled_test_class_roots
    assert_equal(2, NestedSetWithStringScope.roots.size)
    assert_equal(10, NestedSet.roots.size) # May change if STI behavior changes
  end
  
  def disabled_test_check_all_1
    assert NestedSetWithStringScope.check_all
    NestedSetWithStringScope.update_all("lft = 3", "id = 103")
    assert_raise(ActiveRecord::ActiveRecordError) {NestedSetWithStringScope.check_all}
  end
  
  def disabled_test_check_all_2
    NestedSetWithStringScope.update_all("lft = lft + 1", "lft > 11 AND root_id = 101")
    NestedSetWithStringScope.update_all("rgt = rgt + 1", "lft > 11 AND root_id = 101")
    assert_raise(ActiveRecord::ActiveRecordError) {NestedSetWithStringScope.check_all} 
  end
  
  def disabled_test_check_all_3
    NestedSetWithStringScope.update_all("lft = lft + 2", "lft > 11 AND root_id = 101")
    NestedSetWithStringScope.update_all("rgt = rgt + 2", "lft > 11 AND root_id = 101")
    assert_raise(ActiveRecord::ActiveRecordError) {NestedSetWithStringScope.check_all} 
  end
  
  ##########################################
	# CALLBACK TESTS
	##########################################
  # If we change behavior of virtual roots, this test may change
  def disabled_test_before_create
    ns = NestedSetWithSymbolScope.create(:root_id => 1234)
    assert_equal(1, ns.lft)
    assert_equal(2, ns.rgt)
    ns = NestedSetWithSymbolScope.create(:root_id => 1234)
    assert_equal(3, ns.lft)
    assert_equal(4, ns.rgt)
  end
  
  # test pruning a branch. only works if we allow the deletion of nodes with children
  def disabled_test_destroy
    big_tree = NestedSetWithStringScope.find(4001)
    
    # Make sure we have the right one
    assert_equal(3, big_tree.direct_children.length)
    assert_equal(10, big_tree.full_set.length)
    
    NestedSetWithStringScope.find(4005).destroy

    big_tree = NestedSetWithStringScope.find(4001)
    
    assert_equal(7, big_tree.full_set.length)
    assert_equal(2, big_tree.direct_children.length)
    
    assert_equal(1, NestedSetWithStringScope.find(4001).lft)
    assert_equal(2, NestedSetWithStringScope.find(4002).lft)
    assert_equal(3, NestedSetWithStringScope.find(4003).lft)
    assert_equal(4, NestedSetWithStringScope.find(4003).rgt)
    assert_equal(5, NestedSetWithStringScope.find(4004).lft)
    assert_equal(6, NestedSetWithStringScope.find(4004).rgt)
    assert_equal(7, NestedSetWithStringScope.find(4002).rgt)
    assert_equal(8, NestedSetWithStringScope.find(4008).lft)
    assert_equal(9, NestedSetWithStringScope.find(4009).lft)
    assert_equal(10, NestedSetWithStringScope.find(4009).rgt)
    assert_equal(11, NestedSetWithStringScope.find(4010).lft)
    assert_equal(12, NestedSetWithStringScope.find(4010).rgt)
    assert_equal(13, NestedSetWithStringScope.find(4008).rgt)
    assert_equal(14, NestedSetWithStringScope.find(4001).rgt)
  end
  
  def disabled_test_destroy_2
    assert set2(1).check_subtree
    assert set2(10).destroy    
    assert set2(1).reload.check_subtree
    assert set2(9).children.empty?
    assert set2(9).destroy
    assert_equal 15, set2(4).rgt
    assert set2(1).reload.check_subtree
    assert NestedSetWithStringScope.check_all
  end
  
  def disabled_test_destroy_3
    assert set2(3).destroy
    assert_equal(2, set2(1).children.size)
    assert_equal(0, NestedSetWithStringScope.find(:all, :conditions => "id > 104 and id < 108").size)
    assert_equal(6, set2(1).full_set.size)
    assert_equal(3, set2(2).rgt)
    assert_equal(4, set2(4).lft)
    assert_equal(12, set2(1).rgt)
    assert set2(1).check_subtree
  end
  
  def disabled_test_destroy_root
    NestedSetWithStringScope.find(4001).destroy
    assert_equal(0, NestedSetWithStringScope.count(:conditions => "root_id = 42"))
  end            
  
  ##########################################
	# QUERY METHOD TESTS
	##########################################
  def set(id) NestedSet.find(3000 + id) end # helper method
  
  def set2(id) NestedSetWithStringScope.find(100 + id) end # helper method
  
  def disabled_test_root?
    assert NestedSetWithStringScope.find(4001).root?
    assert !NestedSetWithStringScope.find(4002).root?
  end
  
  def disabled_test_child?
    assert !NestedSetWithStringScope.find(4001).child?
    assert NestedSetWithStringScope.find(4002).child?    
  end
  
  # Deprecated, delete this test when we nuke the method
  def disabled_test_unknown?
    assert !NestedSetWithStringScope.find(4001).unknown?
    assert !NestedSetWithStringScope.find(4002).unknown?        
  end
  
  # Test the <=> method implicitly
  def disabled_test_comparison
    ar = NestedSetWithStringScope.find(:all, :conditions => "root_id = 42", :order => "lft")
    ar2 = NestedSetWithStringScope.find(:all, :conditions => "root_id = 42", :order => "rgt")
    assert_not_equal(ar, ar2)
    assert_equal(ar, ar2.sort)
  end
  
  def disabled_test_root
    assert_equal(NestedSetWithStringScope.find(4001), NestedSetWithStringScope.find(4007).root)
    assert_equal(set2(1), set2(8).root)
    assert_equal(set2(1), set2(1).root)
  end
  
  def disabled_test_roots
    assert_equal([set2(1)], set2(8).roots)
    assert_equal([set2(1)], set2(1).roots)
    assert_equal(NestedSet.find(:all, :conditions => "id > 3000 AND id < 4000").size, set(1).roots.size)
  end
  
  def disabled_test_parent
    ns = NestedSetWithStringScope.create(:root_id => 45)
    assert_equal(nil, ns.parent)
    assert ns.save
    assert_equal(nil, ns.parent)
    assert_equal(set2(1), set2(2).parent)
    assert_equal(set2(3), set2(7).parent)
  end
  
  def disabled_test_ancestors
    assert_equal([], set2(1).ancestors)
    assert_equal([set2(1), set2(4), set2(9)], set2(10).ancestors)
  end
  
  def disabled_test_self_and_ancestors
    assert_equal([set2(1)], set2(1).self_and_ancestors)
    assert_equal([set2(1), set2(4), set2(9), set2(10)], set2(10).self_and_ancestors)
  end
  
  def disabled_test_siblings
    assert_equal([], set2(1).siblings)
    assert_equal([set2(2), set2(4)], set2(3).siblings)
  end
  
  def disabled_test_self_and_siblings
    assert_equal([set2(1)], set2(1).self_and_siblings)
    assert_equal([set2(2), set2(3), set2(4)], set2(3).self_and_siblings)    
  end
  
  def disabled_test_level
    assert_equal(0, set2(1).level)
    assert_equal(1, set2(3).level)
    assert_equal(3, set2(10).level)
  end
  
  def disabled_test_children_count
    assert_equal(0, set2(10).children_count)
    assert_equal(1, set2(3).level)
    assert_equal(3, set2(10).level)    
  end
  
  def disabled_test_full_set
    assert_equal(NestedSetWithStringScope.find(:all, :conditions => "root_id = 101", :order => "lft"), set2(1).full_set)
    assert_equal([set2(4), set2(8), set2(9), set2(10)], set2(4).full_set)
    assert_equal([set2(2)], set2(2).full_set)
    assert_equal([set2(2)], set2(2).full_set(:exclude => nil))
    assert_equal([set2(2)], set2(2).full_set(:exclude => []))
    assert_equal([], set2(1).full_set(:exclude => 101))
    assert_equal([], set2(1).full_set(:exclude => set2(1)))
    ns = NestedSetWithStringScope.create(:root_id => 234)
    assert_equal([], ns.full_set(:exclude => ns))
    assert_equal([set2(4), set2(8), set2(9)], set2(4).full_set(:exclude => set2(10)))
    assert_equal([set2(4), set2(8)], set2(4).full_set(:exclude => set2(9))) 
  end
    
  def disabled_test_all_children
    assert_equal(NestedSetWithStringScope.find(:all, :conditions => "root_id = 101 AND id > 101", :order => "lft"), set2(1).all_children)
    assert_equal([set2(8), set2(9), set2(10)], set2(4).all_children)
    assert_equal([set2(8), set2(9)], set2(4).all_children(:exclude => set2(10)))
    assert_equal([set2(8)], set2(4).all_children(:exclude => set2(9)))
    assert_equal([set2(2), set2(4), set2(8)], set2(1).all_children(:exclude => [set2(9), 103]))
    assert_equal([set2(2), set2(4), set2(8)], set2(1).all_children(:exclude => [set2(9), 103, 106]))
  end
  
  def disabled_test_children
    assert_equal([], set2(10).children) 
    assert_equal([], set(1).children) 
    assert_equal([set2(2), set2(3), set2(4)], set2(1).children) 
    assert_equal([set2(5), set2(6), set2(7)], set2(3).children) 
    assert_equal([NestedSetWithStringScope.find(4006), NestedSetWithStringScope.find(4007)], NestedSetWithStringScope.find(4005).children) 
  end
  
  ##########################################
	# INDEX-CHECKING METHOD TESTS
	##########################################
  def disabled_test_check_subtree
    root = set2(1)
    assert root.check_subtree
    # need to use update_all to get around attr_protected
    NestedSetWithStringScope.update_all("rgt = #{root.lft + 1}", "id = #{root.id}")
    assert_raise(ActiveRecord::ActiveRecordError) {root.reload.check_subtree}
    assert set2(4).check_subtree
    NestedSetWithStringScope.update_all("lft = 17", "id = 110")
    assert_raise(ActiveRecord::ActiveRecordError) {set2(4).reload.check_subtree}
    NestedSetWithStringScope.update_all("rgt = 18", "id = 110")
    assert set2(10).check_subtree
    NestedSetWithStringScope.update_all("rgt = NULL", "id = 4002")
    assert_raise(ActiveRecord::ActiveRecordError) {NestedSetWithStringScope.find(4001).reload.check_subtree}
    # this method receives lots of additional testing through tests of check_full_tree and check_all
  end
  
  def disabled_test_check_full_tree
    assert set2(1).check_full_tree
    assert NestedSetWithStringScope.find(4006).check_full_tree
    NestedSetWithStringScope.update_all("rgt = NULL", "id = 4002")
    assert_raise(ActiveRecord::ActiveRecordError) {NestedSetWithStringScope.find(4006).check_full_tree}
    NestedSetWithStringScope.update_all("rgt = 0", "id = 4001")
    assert_raise(ActiveRecord::ActiveRecordError) {NestedSetWithStringScope.find(4006).check_full_tree}
    NestedSetWithStringScope.update_all("rgt = rgt + 1", "id > 101")
    NestedSetWithStringScope.update_all("lft = lft + 1", "id > 101")
    assert_raise(ActiveRecord::ActiveRecordError) {set2(4).check_full_tree}
  end
  
  def disabled_test_check_full_tree_orphan
    ns = NestedSetWithStringScope.create(:root_id => 101)
    assert_raise(ActiveRecord::ActiveRecordError) {set2(3).check_full_tree}
  end
  
  def disabled_test_check_full_tree_endless_loop
    ns = NestedSetWithStringScope.create(:root_id => 101)
    NestedSetWithStringScope.update_all("parent_id = #{ns.id}", "id = #{ns.id}")
    assert_raise(ActiveRecord::ActiveRecordError) {set2(6).check_full_tree}
  end
    
  ##########################################
	# INDEX-ALTERING (UPDATE) METHOD TESTS
	##########################################
	def disabled_test_move_to_left_of # this method undergoes additional testing elsewhere
	  set2(2).move_to_left_of(set2(3)) # should cause no change
	  assert_equal(2, set2(2).lft)
	  assert_equal(4, set2(3).lft)
	  assert NestedSetWithStringScope.check_all
	  set2(3).move_to_left_of(set2(2))
	  assert_equal(9, set2(3).rgt)
	  set2(2).move_to_left_of(set2(3))
	  assert_equal(2, set2(2).lft)
	  assert NestedSetWithStringScope.check_all
  end
  
  def disabled_test_move_to_right_of # this method undergoes additional testing elsewhere
 	  set2(3).move_to_right_of(set2(2)) # should cause no change
	  set2(4).move_to_right_of(set2(3)) # should cause no change
	  assert_equal(11, set2(3).rgt)
	  assert_equal(19, set2(4).rgt)
	  assert NestedSetWithStringScope.check_all
	  set2(3).move_to_right_of(set2(4))
	  assert_equal(19, set2(3).rgt)
	  set2(4).move_to_right_of(set2(3))
	  assert_equal(4, set2(3).lft)
	  assert NestedSetWithStringScope.check_all
  end
  
  def disabled_test_adding_children
    assert(set(1).unknown?)
    assert(set(2).unknown?)
    set(1).add_child set(2)
    
    # Did we maintain adding the parent_ids?
    assert(set(1).root?)
    assert(set(2).child?)
    assert(set(2).parent_id == set(1).id)
    
    # Check boundaries
    assert_equal(set(1).lft, 1)
    assert_equal(set(2).lft, 2)
    assert_equal(set(2).rgt, 3)
    assert_equal(set(1).rgt, 4)
    
    # Check children cound
    assert_equal(set(1).children_count, 1)
    
    set(1).add_child set(3)
    
    #check boundries
    assert_equal(set(1).lft, 1)
    assert_equal(set(2).lft, 2)
    assert_equal(set(2).rgt, 3)
    assert_equal(set(3).lft, 4)
    assert_equal(set(3).rgt, 5)
    assert_equal(set(1).rgt, 6)
    
    # How is the count looking?
    assert_equal(set(1).children_count, 2)

    set(2).add_child set(4)

    # boundries
    assert_equal(set(1).lft, 1)
    assert_equal(set(2).lft, 2)
    assert_equal(set(4).lft, 3)
    assert_equal(set(4).rgt, 4)
    assert_equal(set(2).rgt, 5)
    assert_equal(set(3).lft, 6)
    assert_equal(set(3).rgt, 7)
    assert_equal(set(1).rgt, 8)
    
    # Children count
    assert_equal(set(1).children_count, 3)
    assert_equal(set(2).children_count, 1)
    assert_equal(set(3).children_count, 0)
    assert_equal(set(4).children_count, 0)
    
    set(2).add_child set(5)
    set(4).add_child set(6)
    
    assert_equal(set(2).children_count, 3)

    # Children accessors
    assert_equal(set(1).full_set.length, 6)
    assert_equal(set(2).full_set.length, 4)
    assert_equal(set(4).full_set.length, 2)
    
    assert_equal(set(1).all_children.length, 5)
    assert_equal(set(6).all_children.length, 0)
    
    assert_equal(set(1).direct_children.length, 2)
    assert NestedSetWithStringScope.check_all
  end

  def disabled_test_common_usage
    mixins(:set_1).add_child(mixins(:set_2))
    assert_equal(1, mixins(:set_1).direct_children.length)

    mixins(:set_2).add_child(mixins(:set_3))                      
    assert_equal(1, mixins(:set_1).direct_children.length)     
    
    # Local cache is now out of date!
    # Problem: the update_alls update all objects up the tree
    mixins(:set_1).reload
    assert_equal(2, mixins(:set_1).all_children.length)              
    
    assert_equal(1, mixins(:set_1).lft)
    assert_equal(2, mixins(:set_2).lft)
    assert_equal(3, mixins(:set_3).lft)
    assert_equal(4, mixins(:set_3).rgt)
    assert_equal(5, mixins(:set_2).rgt)
    assert_equal(6, mixins(:set_1).rgt)  
    assert(mixins(:set_1).root?)
                  
    begin
      mixins(:set_4).add_child(mixins(:set_1))
      fail
    rescue
    end
    
    assert_equal(2, mixins(:set_1).all_children.length)
    mixins(:set_1).add_child mixins(:set_4)
    assert_equal(3, mixins(:set_1).all_children.length)
    assert NestedSetWithStringScope.check_all
  end
  
  def disabled_test_set_parent_1
    bill = NestedSetWithStringScope.new(:root_id => 101, :pos => 2)
    assert_raise(ActiveRecord::ActiveRecordError) { bill.move_to_child_of(set2(1)) }    
    assert_raise(ActiveRecord::ActiveRecordError) { set2(1).move_to_child_of(set2(1)) }    
    assert_raise(ActiveRecord::ActiveRecordError) { set2(4).move_to_child_of(set2(9)) }    
    assert bill.save
    assert set2(1).reload.check_subtree
    assert bill.move_to_left_of(set2(3))
    assert_equal set2(1), bill.parent
    assert_equal 4, bill.lft
    assert_equal 5, bill.rgt
    assert_equal 3, set2(2).reload.rgt
    assert_equal 6, set2(3).reload.lft
    assert_equal 22, set2(1).reload.rgt
    assert set2(1).reload.check_subtree
    assert NestedSetWithStringScope.check_all
  end
  
  def disabled_test_set_parent_2
    bill = NestedSetWithStringScope.new(:root_id => 101)
    assert set2(1).check_subtree
    assert bill.save
    assert bill.move_to_child_of(set2(10))
    assert_equal set2(10), bill.parent
    assert_equal 17, bill.lft
    assert_equal 18, bill.rgt
    assert_equal 16, set2(10).reload.lft
    assert_equal 19, set2(10).reload.rgt
    assert_equal 15, set2(9).reload.lft
    assert_equal 20, set2(9).reload.rgt
    assert_equal 21, set2(4).reload.rgt
    assert set2(9).reload.check_subtree
    assert set2(4).reload.check_subtree
    assert set2(1).reload.check_subtree
    assert NestedSetWithStringScope.check_all
  end
  
  def disabled_test_set_parent_3
    bill = NestedSetWithStringScope.new(:root_id => 101)
    assert bill.save
    assert bill.move_to_child_of(set2(3))
    assert set2(1).reload.check_subtree
    assert NestedSetWithStringScope.check_all
  end
  
  def disabled_test_move_1
    set2(4).move_to_child_of(set2(3))
    assert_equal(set2(3), set2(4).reload.parent)
    assert_equal(1, set2(1).reload.lft)
    assert_equal(20, set2(1).reload.rgt)
    assert_equal(4, set2(3).reload.lft)
    assert_equal(19, set2(3).reload.rgt)
    assert set2(1).reload.check_subtree
    assert NestedSetWithStringScope.check_all
  end
  
  def disabled_test_move_2
    initial = set2(1).full_set
    assert_raise(ActiveRecord::ActiveRecordError) { set2(3).move_to_child_of(set2(6)) } # can't set a current child as the parent-- creates a loop
    assert_raise(ActiveRecord::ActiveRecordError) { set2(3).move_to_child_of(set2(3)) }
    set2(2).move_to_child_of(set2(5))
    set2(4).move_to_child_of(set2(2))
    set2(10).move_to_right_of(set2(3))
    
    assert_equal 105, set2(2).parent_id
    assert_equal 102, set2(4).parent_id
    assert_equal 101, set2(10).parent_id
    set2(3).reload
    set2(10).reload
    assert_equal 19, set2(10).rgt
    assert_equal 17, set2(3).rgt
    assert_equal 2, set2(3).lft
    set2(1).reload
    assert set2(1).check_subtree
    set2(4).move_to_right_of(set2(3))
    set2(10).move_to_child_of(set2(9))
    set2(2).move_to_left_of(set2(3))
    
    # now everything should be back where it started-- check against initial
    final = set2(1).reload.full_set
    assert_equal(initial, final)
    for i in 0..9
      assert_equal(initial[i]['parent_id'], final[i]['parent_id'])
      assert_equal(initial[i]['lft'], final[i]['lft'])
      assert_equal(initial[i]['rgt'], final[i]['rgt'])
    end
    assert NestedSetWithStringScope.check_all
  end
  
  ##########################################
	# BUG-SPECIFIC TESTS
	##########################################
  def disabled_test_ticket_17
    main = Category.new
    main.save
    sub = Category.new
    sub.save
    sub.move_to_child_of main
    sub.save
    main.save
    
    assert_equal(1, main.children_count)
    assert_equal([main, sub], main.full_set)
    assert_equal([sub], main.all_children)
    
    assert_equal(1, main.lft)
    assert_equal(2, sub.lft)
    assert_equal(3, sub.rgt)
    assert_equal(4, main.rgt)
  end
  
  def disabled_test_ticket_19
    root = Category.create
    first = Category.create
    second = Category.create    
    first.move_to_child_of(root)
    second.move_to_child_of(root) 
    first.reload ## needed because first is stale
    
    # now we should have the situation described in the ticket
    assert_nothing_raised {first.move_to_child_of(second)}
    assert_raise(ActiveRecord::ActiveRecordError) {second.move_to_child_of(first)} # try illegal move
    first.move_to_child_of(root) # move it back
    second.reload ## needed because second is stale
    assert_nothing_raised {first.move_to_child_of(second)} # try it the other way-- first is now on the other side of second
  end

  def test_foo
  end
  
end



###################################################################
## Tests that don't pass yet or haven't been finished

## can we make base.save ignore left and right?
## need to review all index-altering methods and wrap them in transactions.

## need reload at beginning of move_to?
## having reload at the end of move_to could lose unsaved data

## def disabled_test_scope enforcement
# can't move a node to a parent with different scope

# ## Method not written yet: WHERE lft > l AND rgt < r AND rgt - lft = 1
# def disabled_test_terminal_children  
# end
# def disabled_test_terminal_children_count   
# end
# 
# ## incompatible with current default virtual root setup
#def disabled_test_create_new
#  bill = NestedSetWithStringScope.new(:root_id => 47)
#  assert bill.save
#  bill.reload
#  assert_equal 1, bill.lft
#  assert_equal 2, bill.rgt
#  assert_equal nil, bill.parent_id
#end
#
#
#def disabled_test_renumber_all_1
#  NestedSetWithStringScope.update_all "lft = NULL, rgt = NULL"
#  assert_raise(ActiveRecord::ActiveRecordError) {NestedSetWithStringScope.check_all}
#  assert NestedSetWithStringScope.renumber_all
#  set2(1).reload
#  set2(3).reload
#  assert_equal 1, set2(1).lft
#  assert_equal 20, set2(1).rgt
#  assert_equal 4, set2(3).lft
#  assert_equal 11, set2(3).rgt
#  assert NestedSetWithStringScope.check_all
#end
#
#def disabled_test_renumber_all_2
#  set2(8).move_to_child_of(set2(10))
#  NestedSetWithStringScope.find(:all).each { |t|
#    t.lft = ''
#    t.rgt = ''
#    t.save!
#    t.reload
#  }
#  assert_raise(ActiveRecord::ActiveRecordError) {NestedSetWithStringScope.check_all}
#  assert NestedSetWithStringScope.renumber_all
#  set2(1).reload
#  set2(3).reload
#  set2(8).reload
#  assert_equal 1, set2(1).lft
#  assert_equal 20, set2(1).rgt
#  assert_equal 4, set2(3).lft
#  assert_equal 11, set2(3).rgt
#  assert_equal 15, set2(8).lft
#  assert_equal 16, set2(8).rgt
#  assert NestedSetWithStringScope.check_all    
#end
#
#
#def disabled_test_find_insertion_point
#  bill = NestedSetWithStringScope.create(:pos => 2, :root_id => 101)
#  assert_equal 3, bill.find_insertion_point(set2(1))
#  assert_equal 4, bill.find_insertion_point(set2(3))
#  aalfred = NestedSetWithStringScope.create(:pos => 0, :root_id => 101)
#  assert_equal 1, aalfred.find_insertion_point(set2(1))
#  assert_equal 2, aalfred.find_insertion_point(set2(2))
#  assert_equal 12, aalfred.find_insertion_point(set2(4))
#  zed = NestedSetWithStringScope.create(:pos => 99, :root_id => 101)
#  assert_equal 19, zed.find_insertion_point(set2(1))
#  assert_equal 17, zed.find_insertion_point(set2(9))
#  assert_equal 16, zed.find_insertion_point(set2(10))
#  assert_equal 10, set2(4).find_insertion_point(set2(3))
#end
#
## need to close ticket relating to Single Table Inheritance
#def disabled_test_sti
#  assert false
#end
#
#def disabled_test_concurrent_updates
#  assert false
#  # need to make sure that more than one user can be editing a table-- don't update left/rgt values automatically
#  # 1) remove lft/rgt from AR update statement?
#  # 2) only write lft/rgt if parent changed
#  # 3) if parent changed, reload parent to calc lft/rgt
#end
#

# prevent merging of two trees unless supported

#cases
#new record, no parent; new record, parent specified.

#old records: parent same-- no problem; new parent-- move; parent set to null-- make root-- be sure this works

