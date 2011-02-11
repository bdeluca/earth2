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

require File.dirname(__FILE__) + '/../../test_helper'

class GraphHelperTest < HelperTestCase

  include GraphHelper

  def circle_area(radius)
    Math::PI * radius * radius
  end

  def assert_ring_areas_matching(radii)
    ring1_area = circle_area(radii[1]) - circle_area(radii[0])
    for ring_index in (1..radii.size-2)
      ring_area = circle_area(radii[ring_index + 1]) - circle_area(radii[ring_index])
      assert(ring_area - ring1_area < ring_area * 0.0001) # allow for 0.01% error
    end
  end

  def test_level_radii
    for inner in (20..25)
      for outer in (90..95)
        for level_count in (2..10)
          radii = get_level_radii_uncached(inner, outer, level_count)
          assert_ring_areas_matching(radii)
          assert(inner - radii[0] < inner * 0.001)  # allow for 0.1% error
          assert(outer - radii[-1] < outer * 0.001)  # allow for 0.1% error
        end
      end
    end
  end
  
  def assert_rgb(rgb_array, rgb_string)
    assert_equal("rgb(#{rgb_array[0].to_i},#{rgb_array[1].to_i},#{rgb_array[2].to_i})", rgb_string)
  end

  def test_hsl_to_rgb
    # test brightness
    assert_rgb([255, 255, 255], GraphHelper.hsl_to_rgb(0.0, 0.0, 1.0))
    assert_rgb([127, 127, 127], GraphHelper.hsl_to_rgb(0.0, 0.0, 0.5))
    assert_rgb([  0,   0,   0], GraphHelper.hsl_to_rgb(0.0, 0.0, 0.0))

    # test hue
    assert_rgb([255,   0,   0], GraphHelper.hsl_to_rgb(0.0 / 6.0, 1.0, 0.5))
    assert_rgb([254, 255,   0], GraphHelper.hsl_to_rgb(1.0 / 6.0, 1.0, 0.5))  # rounding error due to base2
    assert_rgb([  0, 255,   0], GraphHelper.hsl_to_rgb(2.0 / 6.0, 1.0, 0.5))
    assert_rgb([  0, 254, 255], GraphHelper.hsl_to_rgb(3.0 / 6.0, 1.0, 0.5))  # rounding error due to base2
    assert_rgb([  0,   0, 255], GraphHelper.hsl_to_rgb(4.0 / 6.0, 1.0, 0.5))
    assert_rgb([255,   0, 254], GraphHelper.hsl_to_rgb(5.0 / 6.0, 1.0, 0.5))  # rounding error due to base2

    # test hue + brightness
    assert_rgb([127,   0,   0], GraphHelper.hsl_to_rgb(0.0 / 6.0, 1.0, 0.25))
    assert_rgb([255, 127, 127], GraphHelper.hsl_to_rgb(0.0 / 6.0, 1.0, 0.75))

    # test hue + saturation + brightness
    assert_rgb([255 - 16, 127 + 16, 127 + 16], GraphHelper.hsl_to_rgb(0.0 / 6.0, 0.75, 0.75))
    assert_rgb([255 - 32, 127 + 32, 127 + 32], GraphHelper.hsl_to_rgb(0.0 / 6.0, 0.50, 0.75))
    assert_rgb([255 - 48, 127 + 48, 127 + 48], GraphHelper.hsl_to_rgb(0.0 / 6.0, 0.25, 0.75))
    assert_rgb([255 - 64, 127 + 64, 127 + 64], GraphHelper.hsl_to_rgb(0.0 / 6.0, 0.00, 0.75))
  end

  def test_segments_1
    
  end
end

