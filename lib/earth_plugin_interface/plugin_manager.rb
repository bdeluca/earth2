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

require 'openssl'

require File.join(File.dirname(__FILE__), 'earth_plugin')

class PluginManagerError < RuntimeError
  def initialize(message)
    @message = message
  end

  def to_s
    @message
  end
end

class PluginManager

  @@plugin_module_counter = 1

  def initialize
    @trusted_certificates = nil
  end

  def trusted_certificates
    if @trusted_certificates.nil?
      @trusted_certificates = []
      trusted_certificate_directory = File.join(File.dirname(__FILE__), "..", "..", "config", "certificates")
      Dir.entries(trusted_certificate_directory).each do |filename| 
        certificate_file = File.join(trusted_certificate_directory, filename)
        if File.file?(certificate_file) and File.readable?(certificate_file)
          begin
            certificate = OpenSSL::X509::Certificate.new(File::read(certificate_file))
            @trusted_certificates << certificate
            #puts "Loaded certificate from #{certificate_file} (#{certificate.subject})"
          rescue
            puts "WARNING: cannot load certificate from #{certificate_file}"
          end
        end
      end
      if @trusted_certificates.empty?
        raise PluginManagerError, "No certificates installed"
      end
    end
    @trusted_certificates
  end

  def sign(plugin_filename, private_key)
    code = File.read(plugin_filename)
    signature = private_key.sign(OpenSSL::Digest::SHA1.new, code)
    signature_filename = plugin_filename + ".sha1"
    File.open(signature_filename, "w") { |f| f.write signature }
  end

  def get_plugin_class(code, signature)

    signer = nil
    trusted_certificates.each do |trusted_certificate|
      begin 
        signer = trusted_certificate.subject if trusted_certificate.public_key.verify(OpenSSL::Digest::SHA1.new, signature, code)
      rescue
      end
    end
    if signer.nil?
      raise PluginManagerError, "Plugin signature could not be verified"
    end

    EarthPlugin.on_inheritance do |child|
      @plugin_class = child
    end
    eval("module PluginModule_#{@@plugin_module_counter}\n" + code + "\nend\n")
    @@plugin_module_counter +=1
    new_plugin_class = @plugin_class

    EarthPlugin.validate_plugin_class(new_plugin_class)

    new_plugin_class
  end

  def install_from_file(plugin_filename)
    code = File.read(plugin_filename)
    
    signature_filename = plugin_filename + ".sha1"
    begin
      signature = File.read(signature_filename)
    rescue Errno::ENOENT
      raise PluginManagerError, "Plugin signature not found in #{signature_filename}"
    end

    ENV["RAILS_ENV"] = "development"
    require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')

    new_plugin_class = get_plugin_class(code, signature)

    existing_plugin = Earth::PluginDescriptor::find(:first, :conditions => { :name => new_plugin_class.plugin_name })
    if not existing_plugin.nil? 
      if existing_plugin.version == new_plugin_class.plugin_version
        raise PluginManagerError, "Refusing to install plugin: This version of this plugin is already installed (#{existing_plugin.version} == #{new_plugin_class.plugin_version})."
      elsif existing_plugin.version > new_plugin_class.plugin_version
        raise PluginManagerError, "Refusing to install plugin: A newer version of this plugin is already installed (#{existing_plugin.version} > #{new_plugin_class.plugin_version})."
      end
    end
    Earth::PluginDescriptor::delete(existing_plugin) if existing_plugin
    Earth::PluginDescriptor::create(:name => new_plugin_class.plugin_name, :version => new_plugin_class.plugin_version, :code => code, :sha1_signature => signature)
  end

  def load_plugin(name, last_loaded_version)
    if last_loaded_version
      newPlugin = Earth::PluginDescriptor::find(:first, :conditions => [ "name = ? and version > ?", name, last_loaded_version ])
    else
      newPlugin = Earth::PluginDescriptor::find(:first, :conditions => [ "name = ?", name ])
    end
    return nil unless newPlugin

    new_plugin_class = get_plugin_class(newPlugin.code, newPlugin.sha1_signature)
    
    #logger.info("New plugin \"#{name}\" available (version #{validated_plugin_class.plugin_version})")
    
    new_plugin_class.new
  end
  
end
