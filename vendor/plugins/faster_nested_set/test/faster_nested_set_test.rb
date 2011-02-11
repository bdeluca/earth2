require File.dirname(__FILE__) + '/abstract_unit'
require File.dirname(__FILE__) + '/fixtures/mixin'
require 'pp'

require 'test/unit'

class FasterNestedSetTest < Test::Unit::TestCase
  fixtures :mixins

  # Replace this with your real tests.
  def test_this_plugin
    flunk
  end
end
