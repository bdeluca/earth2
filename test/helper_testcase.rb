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

# Re-raise errors caught by the controller.
class StubController < ApplicationController
  def rescue_action(e) raise e end;
  attr_accessor :request, :url
end

class HelperTestCase < Test::Unit::TestCase

  # Add other helpers here if you need them
  include ActionView::Helpers::ActiveRecordHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::PrototypeHelper

  def setup
    super

    @request    = ActionController::TestRequest.new
    @controller = StubController.new
    @controller.request = @request

    # Fake url rewriter so we can test url_for
    @controller.url = ActionController::UrlRewriter.new @request, {}
    
    ActionView::Helpers::AssetTagHelper::reset_javascript_include_default
  end

  def test_dummy
    # do nothing - required by test/unit
  end
end
