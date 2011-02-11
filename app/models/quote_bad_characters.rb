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

require "iconv"

class QuoteBadCharacters
  # From the iconv_open man page:
  # Locale dependent, in terms of char or wchar_t
  #   (with  machine  dependent  endianness  and  alignment,  and with semantics
  #   depending on the OS and the  current  LC_CTYPE  locale facet)
  #     char, wchar_t
  def initialize(source_encoding = "UTF-8")
    @convert = Iconv.new(source_encoding, "UTF-8")
  end
  
  def quote(text)
    quote_bad_utf8(quote_backslashes(text))
  end
  
  def quote_backslashes(text)
    result = ""
    text.each_byte do |c|
      if c == 92
        result += "\\\\"
      else
        result += c.chr
      end
    end
    result
  end
  
  def quote_bad_utf8(text)
    begin
      @convert.iconv(text)
    rescue Iconv::Failure => c
      c.success + quote_bad_character(c.failed[0]) + c.failed[1..-1]
    end
  end
  
  def quote_bad_character(value)
    "\\" + value.to_s(8)
  end
end
