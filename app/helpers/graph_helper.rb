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

module GraphHelper

  def dump_segments(directory, level_segment_array)

    logger.debug("Dumping segments for directory #{@directory.path}:")
    level_index = 1
    level_segment_array[1..-1].each do |level_segments|
      logger.debug("  Level ##{level_index}:")
      level_segments.each do |segment|
        logger.debug("    #{segment.inspect}")
      end
      level_index += 1
    end
  end
  
  # Given a directory sub-tree, create a 2-dimensional array for
  # presentation of a radial graph. The first dimension corresponds to
  # the level in the sub-tree and the second dimension to the circle
  # segments on that level.
  def create_directory_segments(directory)

    level_segment_array = []

    # Empty for root level
    level_segment_array << nil

    # Prepare arrays for each level below root
    for level in (1..@level_count)
      level_segment_array << Array.new
    end

    # Recursively fill level arrays
    add_segments(1, 360.0, level_segment_array, directory, directory.size.bytes)

    # Post-process level arrays
    for level in (1..@level_count)
      postprocess_segments(level, level_segment_array[level])
    end

    #dump_segments(directory, level_segment_array)

    level_segment_array
  end

  #
  #  Given a list of servers, create a circle (associated with the
  #  server name and the total size of the files on that server) for
  #  each of them, with the circle area corresponding to the relative
  #  size of the total data of that server.  Arrange the circles so 
  #  that the largest one is in the center and smaller ones get arranged 
  #  around it.
  #
  def create_server_circles()
    #
    #  For each server, determine a (relative) circle radius on an
    #  arbitrary scale and sort descending by the radius (largest
    #  circle first).
    #
    servers_and_radius = @servers.select { |server| server.size.bytes > 0 }.map do |server|
      { :server => server, :relative_radius => Math.sqrt(server.size.bytes) }
    end

    servers_and_radius.sort! do |entry1, entry2|
      entry2[:relative_radius] - entry1[:relative_radius]
    end

    #
    #  Calculate the distance, or "gap", between two adjacent circles.
    #  Since this is going to be scaled later by a yet-unknown-value,
    #  but needs to be known in advance, we're using heuristics to
    #  determine a good value for it that stays approximately equal in
    #  absolute values.
    #  
    #  The heuristics used here calculate the total relative area of
    #  all circles, determines the radius of a circle with this area,
    #  and uses a percentage of that radius.
    #
    total_estd_radius = Math.sqrt(servers_and_radius.inject(0) { |area, sr| area + sr[:relative_radius] * sr[:relative_radius] })
    gap = 0.04 * total_estd_radius

    # derive a minimum circle radius from the estimated radius as well
    # so that tiny servers are still clickable
    min_radius = 0.20 * total_estd_radius

    #
    #  The point around which circles are arranged for now (coordinate system origin)
    #
    screen_center = Point.new(0, 0)

    #
    #  Start by creating a circle for the largest server in the center of the screen.
    #
    server_circles = [ ServerCircle.new(screen_center, servers_and_radius[0][:relative_radius],
                                        servers_and_radius[0][:server]) ]

    #  For all other servers...
    servers_and_radius[1..-1].each do |server_and_radius|

      radius = [min_radius, server_and_radius[:relative_radius]].max

      if server_circles.size == 1
        # Place the circle for the second-largeset server vertically
        # above the first one, separated by "gap"
        center = Point.new(0, -server_circles[0].radius - radius - gap)
        server_circles << ServerCircle.new(center, radius, server_and_radius[:server])
      else

        # For all other circles, determine the best location by
        # placing it in "corners" between all existing circles and
        # choosing the "corner" the closest to the screen center where
        # the circle can be placed without overlapping any of the
        # existing circles.

        best_location = nil

        # for each combination of existing circles
        server_circles.each_with_index do |circle1, outer_index|
          server_circles[outer_index+1 .. -1].each do |circle2|

            # find the intersection between the circles enlarged by (radius+gap)
            # which are potential locations for the new circle
            intersections = circle_circle_intersection(circle1.center,
                                                       circle1.radius + radius + gap,
                                                       circle2.center,
                                                       circle2.radius + radius + gap)

            # if there are intersections
            if intersections

              # for each of the two intersections
              intersections.each do |intersection|
                
                # if the new circle doesn't overlap any existing circle
                if not server_circles.any? { |circle| circle.overlaps(intersection, radius) }

                  # if the new circle is the first match, or if it is
                  # closer to the screen center than the previous
                  # match, or if it is at the same distance as the
                  # previous match (taking float imprecisions into
                  # account) and higher up the screen, use this as the
                  # new best match
                  if best_location.nil?
                    best_location = intersection
                  else
                    this_distance_sqr = intersection.distance_sqr(screen_center)
                    best_distance_so_far_sqr = best_location.distance_sqr(screen_center)

                    if this_distance_sqr < best_distance_so_far_sqr \
                      or ((Math.sqrt(this_distance_sqr) - Math.sqrt(best_distance_so_far_sqr)).abs < 0.00001 \
                          and intersection.y < best_location.y)

                      best_location = intersection
                    end
                  end
                end
              end
            end
          end
        end

        server_circles << ServerCircle.new(best_location, radius, server_and_radius[:server])
      end
    end

    maxVal = 10000000
    minVal = -10000000

    bounds = server_circles.inject({:min_x => maxVal, :min_y => maxVal, :max_x => minVal, :max_y => minVal}) \
    do | bounds, server_circle | 
      { \
        :min_x => [bounds[:min_x], server_circle.center.x - server_circle.radius].min, \
        :min_y => [bounds[:min_y], server_circle.center.y - server_circle.radius].min, \
        :max_x => [bounds[:max_x], server_circle.center.x + server_circle.radius].max, \
        :max_y => [bounds[:max_y], server_circle.center.y + server_circle.radius].max, \
      }
    end

    all_center = Point.new((bounds[:min_x] + bounds[:max_x]) / 2, \
                           (bounds[:min_y] + bounds[:max_y]) / 2);

    all_radius = server_circles.inject(0) \
    do | all_radius, server_circle | 
      [all_radius, server_circle.center.distance(all_center) + server_circle.radius].max
    end

    #max_radius = server_circles.inject(0) do | max_radius, server_circle | 
    #  [max_radius, server_circle.center.distance(screen_center) + server_circle.radius].max
    #end

    server_circles.each do |server_circle|
      server_circle.translate(-all_center.x, -all_center.y)
      server_circle.scale(90 / all_radius)
    end

    server_circles
  end

private

  # Calculate the next outer radius of a segment-ring so that the area of the
  # segment rings stays constant.
  #
  # given radii r1, r2 find r3
  #
  # a1 = pi * r1 * r1   -> area within r1
  # a2 = pi * r2 * r2   -> area within r2
  # a3 = pi * r3 * r3   -> area within r3
  #
  # a1' = a2 - a1       -> area of ring between r1 and r2
  # a1' = pi * r2 * r2 - pi * r1 * r1
  #
  # a2' = a3 - a2       -> area of ring between r2 and r3
  # a2' = pi * r3 * r3 - pi * r2 * r2
  #
  # a2' = a1'           -> area should remain constant
  #
  # solve for r3:
  #
  # pi * r2 * r2 - pi * r1 * r1  =  pi * r3 * r3 - pi * r2 * r2        |  /pi
  # r2 * r2 - r1 * r1            =  r3 * r3 - r2 * r2                  |  /pi
  # r2 * r2 - r1 * r1            =  r3 * r3 - r2 * r2                  |  + r2 * r2
  # 2 * r2 * r2 - r1 * r1        =  r3 * r3                            |  sqrt        
  # r3                           =  Math.sqrt(2 * r2 * r2 - r1 * r1)
  #
  # solving for outer levels gives:
  # r4                           =  Math.sqrt(3 * r2 * r2 - 2 * r1 * r1)
  # r5                           =  Math.sqrt(4 * r2 * r2 - 3 * r1 * r1)
  # etc.
  #
  # solving that for r2 gives:
  # r2                           =  Math.sqrt((outer * outer + inner * inner) / @level_count)
  def get_level_radii
    inner = 20
    outer = 90
    
    if @level_radii.nil?
      @level_radii = get_level_radii_uncached(inner, outer, @level_count)
    end    
    @level_radii
  end

  def get_level_radii_uncached(inner, outer, count)
    (0..count).map do |level|
      Math.sqrt(outer.to_f * outer * level / count \
                + inner.to_f * inner * (level.to_f * (count - 1) / count - level + 1))
    end
  end

  # Convert a color from HSL (Hue, Saturation, Lightness) colorspace to RGB. The
  # HSL colorspace is also known as HLS or HSI (Hue, Saturation, Intensity.)
  # 
  # The HSL colorspace should not be confused with the HSV (Hue, Saturation, Value)
  # colorspace, also known as HSB (Hue, Saturation, Brightness).
  #
  # For a description and comparison to HSV see here:
  # http://en.wikipedia.org/wiki/HSL_color_space
  #
  # This is used for determining the color of a graph segment as a
  # function of its angular position and depth in the tree (if
  # graph_coloring_mode=rainbow is configured in earth-webapp.yml) or
  # as a function of its type and depth (if
  # graph_coloring_mode=by_type).
  #
  def GraphHelper.hsl_to_rgb(h, s, l) 
    if s == 0
      r = g = b = [0, [255, 255 * l].min].max.to_i
    else
      if l < 0.5
        var_2 = l * (1.0 + s)
      else
        var_2 = l + s - s * l
      end
      var_1 = 2.0 * l - var_2

      components = [ \
        [ var_1, var_2, h + 1.0 / 3.0 ], \
        [ var_1, var_2, h ], \
        [ var_1, var_2, h - 1.0 / 3.0 ] \
      ].map do | v1, v2, vH |
        vH += 1 if vH < 0
        vH -= 1 if vH > 1
        if vH < 1.0 / 6.0
          v1 + (v2 - v1) * 6.0 * vH
        elsif vH < 1.0 / 2.0
          v2
        elsif vH < 2.0 / 3.0
          v1 + (v2 - v1) * (2.0 / 3.0 - vH) * 6.0
        else
          v1
        end
      end

      r, g, b = components.map do |col|
        [0, [255, 255 * col].min].max.to_i
      end
    end
    "rgb(#{r},#{g},#{b})"
  end

  # Simple helper class for representing a 2D Point.
  class Point

    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def distance_sqr(other)
      dx = other.x - @x
      dy = other.y - @y
      dx*dx + dy*dy
    end

    def distance(other)
      Math.sqrt(distance_sqr(other))
    end

    def to_s
      "#{@x},#{@y}"
    end
  end

  def GraphHelper::format_human(size)
    units = ApplicationHelper::human_units_of(size)
    "#{ApplicationHelper::human_size_in(units, size)} #{units}"
  end

  def add_segments(level, angle_range, level_segment_array, directory, parent_bytes)

    if (level > @level_count)
      return
    end

    level_segments = level_segment_array[level]

    if directory.nil?
      empty_segment = Segment.new(:angle => angle_range, :type => :empty)
      level_segments << empty_segment
      add_segments(level + 1, angle_range, level_segment_array, nil, 0)
    else

      if parent_bytes == 0
        parent_bytes = 1
      end

      small_directories = Array.new
      big_directories = Array.new
      small_directories_bytes = 0

      directory.children.each do |child|
        child_bytes = child.size.bytes
        segment_angle = child_bytes * angle_range / parent_bytes
        if segment_angle >= @minimum_angle
          big_directories << child
        else
          small_directories_bytes += child_bytes
          small_directories << child
        end
      end

      big_files = Array.new
      small_files = Array.new
      small_files_bytes = 0

      directory.files.each do |file|
        segment_angle = file.bytes * angle_range / parent_bytes
        if segment_angle >= @minimum_angle
          big_files << file
        else
          small_files_bytes += file.bytes
          small_files << file
        end
      end

      small_files_angle = small_files_bytes * angle_range / parent_bytes
      if @remainder_mode == :drop and small_files_angle < @minimum_angle
        parent_bytes -= small_files_bytes
        small_files = []
        small_files_bytes = 0
        small_files_angle = 0
      end

      small_directories_angle = small_directories_bytes * angle_range / parent_bytes
      if @remainder_mode == :drop and small_directories_angle < @minimum_angle
        parent_bytes -= small_directories_bytes
        small_directories = []
        small_directories_bytes = 0
        small_directories_angle = 0
      end

      small_files_angle = small_files_bytes * angle_range / parent_bytes
      if @remainder_mode == :drop and small_files_angle < @minimum_angle
        parent_bytes -= small_files_bytes
        small_files = []
        small_files_bytes = 0
        small_files_angle = 0
      end

      if small_directories_angle > 0
        if small_directories.size > 1
          segment = Segment.new(:angle => small_directories_angle, 
                                :type => ((small_directories_angle >= @minimum_angle or @remainder_mode != :empty) ? :directory : :empty),
                                :name => "#{small_directories.size} directories", 
                                :tooltip => "#{small_directories.size} directories in ...#{directory.path_relative_to(@directory)}/ (#{GraphHelper::format_human(small_directories_bytes)})")
        else
          child = small_directories[0]
          segment = Segment.new(:angle => small_directories_angle, 
                                :type => ((small_directories_angle >= @minimum_angle or @remainder_mode != :empty) ? :directory : :empty),
                                :name => "#{child.name}/", 
                                :href => url_for(:controller => :graph, 
                                                 :escape => false,
                                                 :overwrite_params => {:server => @server.name, 
                                                                       :action => nil,
                                                                       :path => child.path}),
                                :tooltip => "...#{child.path_relative_to(@directory)}/ (#{GraphHelper::format_human(child.size.bytes)})")
        end
        level_segments << segment
        
        add_segments(level + 1, small_directories_angle, level_segment_array, nil, 0)
      end

      big_directories.each do |big_directory|
        segment_angle = big_directory.size.bytes * angle_range / parent_bytes
        segment = Segment.new(:angle => segment_angle, 
                              :type => :directory,
                              :name => "#{big_directory.name}/", 
                              :href => url_for(:controller => :graph, 
                                               :escape => false,
                                               :overwrite_params => {:server => @server.name, 
                                                                     :action => nil,
                                                                     :path => big_directory.path}),
                              :tooltip => "...#{big_directory.path_relative_to(@directory)}/ (#{GraphHelper::format_human(big_directory.size.bytes)})")
        level_segments << segment
        add_segments(level + 1, segment_angle, level_segment_array, big_directory, big_directory.size.bytes)
      end
      
      if small_files_angle > 0
        if small_files.size > 1
          small_files_segment = Segment.new(:angle => small_files_angle, 
                                            :type => ((small_files_angle >= @minimum_angle or @remainder_mode != :empty) ? :file : :empty),
                                            :name => "#{small_files.size} files",
                                            :tooltip => "#{small_files.size} files in ...#{directory.path_relative_to(@directory)}/ (#{GraphHelper::format_human(small_files_bytes)})")
        else
          file = small_files[0]
          small_files_segment = Segment.new(:angle => small_files_angle, 
                                            :type => ((small_files_angle >= @minimum_angle or @remainder_mode != :empty) ? :file : :empty),
                                            :name => file.name,
                                            :tooltip => "...#{directory.path_relative_to(@directory)}/#{file.name} (#{GraphHelper::format_human(file.size)})")
        end
        level_segments << small_files_segment
      end

      files_total_angle = small_files_angle
      big_files.each do |file|
        angle = file.bytes * angle_range / parent_bytes
        file_segment = Segment.new(:angle => angle, 
                                   :type => :file,
                                   :name => file.name,
                                   :tooltip => "...#{directory.path_relative_to(@directory)}/#{file.name} (#{GraphHelper::format_human(file.bytes)})")
        level_segments << file_segment
        files_total_angle += angle
      end

      add_segments(level + 1, files_total_angle, level_segment_array, nil, 0)
    end
  end


  class Segment

    attr_reader :angle
    attr_reader :name
    attr_reader :href
    attr_reader :segment_id
    attr_reader :tooltip
    attr_writer :angle
    attr_writer :start_angle
    attr_writer :inner_radius
    attr_writer :outer_radius
    attr_writer :level
    attr_writer :segment_id

    def initialize(args)
      @angle = args[:angle]
      @name = args[:name] || ""
      @href = args[:href]
      @tooltip = args[:tooltip]
      @type = args[:type]
    end

    def empty?
      @type == :empty
    end

    def directory?
      @type == :directory
    end

    def get_point_on_circle(radius, angle)

      return Point.new(Math.cos(angle * Math::PI / 180.0) * radius,
                       Math.sin(angle * Math::PI / 180.0) * radius)
    end

    def get_color
      GraphHelper.hsl_to_rgb((@start_angle + @angle /2) / 360.0, 0.5, 0.8 - @level * 0.05)
    end

    def get_svg_divider_path(level)
      get_svg_divider_path_radius(@inner_radius, @outer_radius)
    end 

    def get_svg_divider_path_radius(inner, outer)
      "M#{get_point_on_circle(inner, @start_angle)} L#{get_point_on_circle(outer, @start_angle)}"
    end 

    def get_svg_path_internal(level, radius, reverse=false)
      if @angle < 360

        angle1 = @start_angle
        angle2 = @start_angle + @angle

        if reverse
          angle2, angle1 = angle1, angle2
        end

        middle_start = get_point_on_circle(radius, angle1)
        middle_end = get_point_on_circle(radius, angle2)

        if @angle < 180
          flags = 0
        else
          flags = 1
        end

        if reverse
          flags2 = 0
        else
          flags2 = 1
        end

        "M#{middle_start} " + \
        "A#{radius},#{radius} 0 #{flags},#{flags2} #{middle_end} "
      else
        middle_start = get_point_on_circle(radius, 90)
        middle_end = get_point_on_circle(radius, 270)

        "M#{middle_start} " + \
        "A#{radius},#{radius} 0 0,1 #{middle_end} " + \
        "A#{radius},#{radius} 0 0,1 #{middle_start} "
      end
    end

    def get_svg_text_path(level)
      get_svg_path_internal(level, (@inner_radius + @outer_radius) / 2, @start_angle + @angle/2 < 180)
    end

    def get_svg_path_outer(level)
      get_svg_path_internal(level, @outer_radius)
    end

    def get_svg_path(extension=false, reverse=false)

        if not extension
          radius1 = @inner_radius
          radius2 = @outer_radius
        else
          radius1 = @outer_radius
          radius2 = @outer_radius + 10
        end

      if @angle < 360

        angle1 = @start_angle
        angle2 = @start_angle + @angle

        if reverse
          angle2, angle1 = angle1, angle2
        end

        inner_start = get_point_on_circle(radius1, angle1)
        inner_end = get_point_on_circle(radius1, angle2)
        outer_end = get_point_on_circle(radius2, angle2)
        outer_start = get_point_on_circle(radius2, angle1)
      
        if @angle < 180
          flags = "0"
        else
          flags = "1"
        end
        "M#{inner_start} " + \
        "A#{radius1},#{radius1} 0 #{flags},1 #{inner_end} " + \
        "L#{outer_end} " + \
        "A#{radius2},#{radius2} 0 #{flags},0 #{outer_start} " + \
        "L#{inner_start} "
      else
        inner_start = get_point_on_circle(radius1, 0)
        inner_end = get_point_on_circle(radius1, 180)
        outer_end = get_point_on_circle(radius2, 180)
        outer_start = get_point_on_circle(radius2, 0)

        "M#{inner_start} " + \
        "A#{radius1},#{radius1} 0 0,1 #{inner_end} " + \
        "A#{radius1},#{radius1} 0 0,1 #{inner_start} " + \
        "L#{outer_start} " + \
        "A#{radius2},#{radius2} 0 0,0 #{outer_end} " + \
        "A#{radius2},#{radius2} 0 0,0 #{outer_start} " + \
        "L#{inner_start} "
      end
    end

  end

  def postprocess_segments(level, level_segments)
    start_angle = 10
    segment_id = 1

    level_radii = get_level_radii

    inner_radius = level_radii[level - 1]
    outer_radius = level_radii[level]

    prev_segment = nil
    remove_segment_indices = Array.new
    level_segments.each_index do | index |
      segment = level_segments[index]
      if (not prev_segment.nil?) and prev_segment != segment and prev_segment.empty? and segment.empty?
        prev_segment.angle += segment.angle
        remove_segment_indices << index
      else
        segment.start_angle = start_angle

        segment.inner_radius = inner_radius
        segment.outer_radius = outer_radius
        segment.level = level
        segment.segment_id = segment_id

        segment_id += 1
        prev_segment = segment
      end
      start_angle += segment.angle
    end
    
    remove_segment_indices.reverse.each do |index|
      level_segments.delete_at(index)
    end

    level_segments.delete_if do |segment|
      segment.angle <= 0
    end
  end


  class ServerCircle
    attr_reader :center
    attr_reader :radius
    attr_reader :server

    def initialize(center, radius, server)
      @center = center
      @radius = radius
      @server = server
    end

    def overlaps(point, radius)
      dr = radius + @radius
      center.distance_sqr(point) < dr*dr
    end

    def scale(value)
      @center = Point.new(@center.x * value, @center.y * value)
      @radius *= value
    end

    def translate(dx, dy)
      @center = Point.new(@center.x + dx, @center.y + dy)
    end
  end

  def abs(val)
    if val < 0
      -val
    else
      val
    end
  end

  # Find the intersection of two circles.
  # Translated from this piece of C code: 
  # http://local.wasp.uwa.edu.au/~pbourke/geometry/2circle/tvoght.c
  def circle_circle_intersection(p0, r0,
                                 p1, r1)

    x0, y0 = p0.x, p0.y
    x1, y1 = p1.x, p1.y

    # dx and dy are the vertical and horizontal distances between
    # the circle centers.
    #
    dx = x1 - x0
    dy = y1 - y0

    # Determine the straight-line distance between the centers.
    d = Math.sqrt(dy*dy + dx*dx)

    # Check for solvability.
    if (d > r0 + r1)
      # no solution. circles do not intersect.
      nil

    elsif (d < abs(r0 - r1))
      # no solution. one circle is contained in the other
      return nil

    else

      # 'point 2' is the point where the line through the circle
      # intersection points crosses the line between the circle
      # centers.  

      # Determine the distance from point 0 to point 2.
      a = (r0*r0 - r1*r1 + d*d) / (2.0 * d)

      # Determine the coordinates of point 2.
      x2 = x0 + (dx * a/d)
      y2 = y0 + (dy * a/d)

      # Determine the distance from point 2 to either of the
      # intersection points.
      h = Math.sqrt((r0*r0) - (a*a))

      # Now determine the offsets of the intersection points from
      # point 2.
      #
      rx = -dy * (h/d)
      ry = dx * (h/d)

      # Determine the absolute intersection points.
      xi = x2 + rx
      xi_prime = x2 - rx
      yi = y2 + ry
      yi_prime = y2 - ry

      [Point.new(xi, yi), Point.new(xi_prime, yi_prime)]
    end
  end

  class SubRect

    @@id = 0

    attr_reader :id
    attr_reader :x
    attr_reader :y
    attr_reader :width
    attr_reader :height
    attr_reader :node
    attr_reader :title

    def initialize(x, y, width, height, node, title=nil)
      @id = @@id
      @@id += 1
      @x = x
      @y = y
      @width = width
      @height = height
      @node = node
      @title = title
    end

    def to_s
      "rect(#{@x} #{@y} #{@width} #{@height} #{title})"
    end

    def area
      @width * @height
    end

    def shrink(amount)

      @x += amount
      @y += amount
      @width -= amount * 2
      @height -= amount * 2
    end

    def title
      if not @node.nil?
        @node.title
      elsif not @title.nil?
        @title
      else
        "UNKNOWN"
      end
    end

    def tooltip
      if not @node.nil?
        @node.tooltip
      elsif not @title.nil?
        @title
      else
        "UNKNOWN"
      end
    end
  end

  class Rectangle

    attr_reader :sub_rectangles    

    def initialize(x, y, width, height)
      @x = x
      @y = y
      @width = width
      @height = height

      @offset_x = 0
      @offset_y = 0
      
      @sub_rectangles = []
    end

    def area
      @width * @height
    end

    def width()
      remaining_width = @width - @offset_x
      remaining_height = @height - @offset_y
      [ remaining_width, remaining_height ].min
    end

    def add_remaining(title)
      @sub_rectangles << SubRect.new(@x + @offset_x, @y + @offset_y, @width - @offset_x, @height - @offset_y, nil, title)
      @offset_x = @width
      @offset_y = @height
    end

    def layoutrow(row, factor)

      remaining_width = @width - @offset_x
      remaining_height = @height - @offset_y

      sum = row.map { |node| node.size.bytes*factor }.sum

      if remaining_height > 0 and remaining_width > 0 and sum > 0 then

        if remaining_width > remaining_height
          # layout horizontally
          width = sum / remaining_height

          left = @offset_x
          top = @offset_y

          row.each do |r|
            height = r.size.bytes*factor/width
            @sub_rectangles << SubRect.new(@x + left, @y + top, width, height, r)
            top += height
          end

          @offset_x += width
        else
          height = sum / remaining_width

          left = @offset_x
          top = @offset_y

          row.each do |r|
            width = r.size.bytes*factor/height
            @sub_rectangles << SubRect.new(@x + left, @y + top, width, height, r)
            left += width
          end

          @offset_y += height
        end

      end
    end

    def worst(row, w, factor)
      s = row.map { |node| node.size.bytes * factor }.sum
      if row.empty? or s == 0 or factor == 0
        0
      else
        [(w*w*row[0].size.bytes*factor)/(s*s), (s*s)/(w*w*row[-1].size.bytes*factor)].max
      end
    end
    
    def squarify(children, row, w, factor) 
      while true
        if not children.empty?
          if children[0].size.bytes*factor < 0
            add_remaining("#{children.size} files")
            break
          else
            c = children[0]
            if row.empty? or worst(row, w, factor) >= worst(row + [c], w, factor) then 
              children = children[1..-1]
              row = row + [c]
            else 
              layoutrow(row, factor); 
              squarify(children, [], width(), factor); 
              break
            end
          end
        else
          layoutrow(row, factor); 
          break
        end
      end
    end 
  end

  class TreemapDirectory

    def initialize(root, directory)
      @root = root
      @directory = directory
    end
    
    def children
      if @children.nil?
        @children = @directory.children.map { |child| TreemapDirectory.new(@root, child) } + 
                    @directory.files.map { |child| TreemapFile.new(self, child) }
        @children.sort! do |entry1, entry2|
          entry2.size - entry1.size
        end
      end
      @children
    end

    def directory
      @directory
    end

    def size
      @directory.size
    end

    def title
      @directory.name
    end

    def relative_path
      @directory.path_relative_to(@root)
    end

    def tooltip
      "...#{relative_path} (#{GraphHelper::format_human(@directory.size.bytes)})"
    end
  end

  class TreemapFile
    def initialize(parent, file)
      @parent = parent
      @file = file
    end

    def directory
      nil
    end

    def size
      @file.size
    end

    def title
      @file.name
    end

    def tooltip
      "...#{@parent.relative_path}/#{@file.name} (#{GraphHelper::format_human(@file.size.bytes)})"
    end

    def children
      nil
    end
  end

  def create_treemap_recursive(node, rect, level, sub_rectangle_array, max_levels)

    total_size = node.children.map { |child| child.size.bytes }.sum
    if total_size > 0
      rect.squarify(node.children, [], rect.width(), rect.area / total_size)

      rect.sub_rectangles.each { |sub_rect| sub_rect.shrink(0.4) }
      
      sub_rectangle_array[level] += rect.sub_rectangles

      if level < max_levels - 1
        for sub_rect in rect.sub_rectangles
          create_treemap_recursive(sub_rect.node, Rectangle.new(sub_rect.x + 0.2, sub_rect.y + 0.2, sub_rect.width - 0.4, sub_rect.height - 0.4), level + 1, sub_rectangle_array, max_levels) unless sub_rect.node.nil? or sub_rect.node.children.nil?
        end
      end
    end
  end

  def create_treemap(directory)

    topNode = TreemapDirectory.new(@directory, directory)

    rect = Rectangle.new(0.0, 0.0, 600.0, 600.0)

    max_levels = 3
    sub_rectangle_array = []
    1.upto(max_levels) { sub_rectangle_array << [] }

    create_treemap_recursive(topNode, rect, 0, sub_rectangle_array, max_levels)

    sub_rectangle_array
  end
end

