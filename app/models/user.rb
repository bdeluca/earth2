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

class User
  cattr_accessor :config
  attr_reader :uid, :name

  @@config = nil    
  def self.config
    @@config = ApplicationController::webapp_config unless @@config
    @@config
  end
  
  @@uid_to_name = ExpiringHash.new(config["ldap_cache_time"].to_i)

  def User.reset_cache
    @@uid_to_name = ExpiringHash.new(config["ldap_cache_time"].to_i)
  end

  def User.ldap_configured?
    config["ldap_server_name"]
  end
  
  require "ldap" if ldap_configured?

  def initialize(uid)
    @uid = uid
    @name = find_name_by_uid_cached(@uid)
  end
 
  # Simple cache
  def find_name_by_uid_cached(uid)
    result = @@uid_to_name[uid]
    if result.nil?
      result = find_name_by_uid_uncached(uid)
      @@uid_to_name[uid] = result
    end
    result
  end
  
  def find_name_by_uid_uncached(uid)
    User.lookup(uid.to_s, config["ldap_user_lookup"]["id_field"], config["ldap_user_lookup"]["name_field"],
        config["ldap_user_lookup"]["base"]) || "#{uid}"
  end
  
  def User.find(uid)
    User.new(uid)
  end
  
  def User.find_by_name(name)
    # If name is just a number treat it as the uid
    if name.to_i.to_s == name
      no = name.to_i
    else
      no = User.lookup(name, config["ldap_user_lookup"]["name_field"], config["ldap_user_lookup"]["id_field"],
        config["ldap_user_lookup"]["base"]).to_i
    end
    return User.new(no)
  end
  
  def User.find_all
    if User.ldap_configured?
      nos = User.lookup_all('*', config["ldap_user_lookup"]["name_field"], config["ldap_user_lookup"]["id_field"],
       config["ldap_user_lookup"]["base"])
      return nos.map{|n| User.new(n)}
    else
      return []
    end
  end
  
  def User.find_matching(m)
    if User.ldap_configured?
      nos = User.lookup_all("*#{m}*", config["ldap_user_lookup"]["name_field"], config["ldap_user_lookup"]["id_field"],
        config["ldap_user_lookup"]["base"])
      return nos.map{|n| User.new(n)}
    else
      return []
    end
  end
  
  private
  
  def User.lookup(value, lookup_field, result_field, base)
    #TODO: Don't make a new connection to the server for every request
    if User.ldap_configured?
      # The following option is not necessary for every installation but
      # we use LDAPv3 internally and our server barks if we bind with a legacy
      # protocol. Sorry :(
      LDAP::Conn.set_option( LDAP::LDAP_OPT_PROTOCOL_VERSION, 3 )
      LDAP::Conn.new(config["ldap_server_name"], config["ldap_server_port"]).bind do |conn|
        conn.search(base, LDAP::LDAP_SCOPE_SUBTREE, "#{lookup_field}=#{value}", result_field) do |e|
          return e.vals(result_field)[0]
        end
      end
      return nil
    else
      return value
    end
  end
  
  def User.lookup_all(value, lookup_field, result_field, base)
    #TODO: Don't make a new connection to the server for every request
    if User.ldap_configured?
      results = []
      # The following option is not necessary for every installation but
      # we use LDAPv3 internally and our server barks if we bind with a legacy
      # protocol. Sorry :(
      LDAP::Conn.set_option( LDAP::LDAP_OPT_PROTOCOL_VERSION, 3 )
      LDAP::Conn.new(config["ldap_server_name"], config["ldap_server_port"]).bind do |conn|
        conn.search(base, LDAP::LDAP_SCOPE_SUBTREE, "#{lookup_field}=#{value}", result_field) do |e|
          results << e.vals(result_field)[0]
        end
      end
      return results
    else
      return [value]
    end
  end
  
end
