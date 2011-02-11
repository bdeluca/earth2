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

class Size
  include Comparable
  attr_accessor :bytes, :blocks, :count
  
  def initialize(bytes, blocks, count)
    @bytes = bytes
    @blocks = blocks
    @count = count
  end
  
  def +(size)
    Size.new(bytes + size.bytes, blocks + size.blocks, count + size.count)
  end

  def -(size)
    Size.new(bytes - size.bytes, blocks - size.blocks, count - size.count)
  end
  
  def ==(size)
    bytes == size.bytes && blocks == size.blocks && count == size.count
  end

  def <=>(anOther)
    bytes <=> anOther.bytes
  end

  def to_s
    units = ApplicationHelper::human_units_of(bytes)
    "#{ApplicationHelper::human_size_in(units, bytes)} #{units}"
  end
end
