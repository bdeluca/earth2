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

class FileMonitor < EarthPlugin
  cattr_accessor :log_all_sql
  cattr_accessor :console_writer
  cattr_accessor :status_info

  self.status_info = "Starting up"

  @logger = nil

  def logger=(logger)
    @logger = logger
  end

  def logger
    @logger || RAILS_DEFAULT_LOGGER
  end

  def self.plugin_name
    "EarthFileMonitor"
  end

  def self.plugin_version
    131
  end

  class ETAPrinter
    def initialize(file_monitor, description, number_of_items)
      @file_monitor = file_monitor
      @description = description
      @number_of_items = number_of_items
      @items_completed = 0
      @last_eta_update = 0
      @min_eta_update_delta = 1.seconds
      @start = Time.new
    end

    def increment()
      @items_completed += 1
      now = Time.new
      time_per_item = (now - @start) / @items_completed
      items_remaining = @number_of_items - @items_completed
      if items_remaining > 0
        if @last_eta_update.to_i + @min_eta_update_delta <= now.to_i
          @last_eta_update = now
          time_remaining = items_remaining * time_per_item
          eta_string = "#{@description} [#{@items_completed}/#{@number_of_items}] ETA: #{(Time.local(2007) + (time_remaining)).strftime('%H:%M:%S')}s"
          @file_monitor.status_info = eta_string
        end
      end
    end
  end
  
  # Set this to true if you want to see the individual SQL commands
  self.log_all_sql = false

  # TODO: Check that paths are not overlapping
  def iteration(cache, only_initial_update = false, force_update_time = nil)

    logger.debug("FileMonitor iteration starting")
    
    # Find the current directory that it's watching
    server = Earth::Server.this_server
    directories = Earth::Directory.roots_for_server(server)

    logger.debug("Top-level directories loaded")    
    
    cache[:top_level_directories] ||= {}

    directories.each do |directory|
      if not cache[:top_level_directories].keys.include? directory.id
        cache[:top_level_directories][directory.id] = directory
        benchmark "Collecting startup data for directory #{directory.path} from database" do
          directory.load_all_children(0)
        end
      end
    end

    cache[:top_level_directories].values.each do |directory|
      if directory.modified.nil?
        benchmark "Doing initial pass on new path #{directory.path}" do
          #
          # FIXME: removing and re-adding the directory is ugly. Find
          # a better way to do this - either by leaving the new
          # directory in the database and just building the tree below
          # it, or by introducing a new database table
          # "daemon_commands" where add/remove/clear requests are
          # queued.
          #
          path = directory.name
          cache[:top_level_directories].delete directory.id
          server.directories.delete(directory)
          new_directory = initial_pass_on_new_directory(path)
          cache[:top_level_directories][new_directory.id] = new_directory
        end
      end
    end
    
    server = Earth::Server.this_server
    server.last_update_finish_time = Time.new.utc
    server.save!
    
    run(cache[:top_level_directories].values, force_update_time) unless only_initial_update
  end
  
  def directory_saved(node)
    @directory_eta_printer.increment if @directory_eta_printer
  end
  
  # Remove all directories on this server from the database
  def database_cleanup
    this_server = Earth::Server.this_server
    benchmark "Clearing old data for this server out of the database" do
      Earth::Directory.delete_all "server_id=#{this_server.id}"
    end  
    this_server.last_update_finish_time = nil
    this_server.save!
  end

  def update(directories, update_time = 0, *args)
    options = { :only_build_directories => false, :initial_pass => false, :show_eta => true }
    options.update(args.first) if args.first
    # TODO: Do this in a nicer way
    total_count = 0
    initial_count = directories.map{|d| d.children_count + 1}.sum
    remaining_count = initial_count
    eta_printer = ETAPrinter.new(self, "Updating directories", remaining_count) if options[:show_eta]
    start = Time.new
    logger.debug("starting update cycle, directories.size is #{directories.size} remaining count is #{remaining_count}")
    directories.each do |directory|
      directory.each do |d|
        total_count += update_non_recursive(d, options)
        remaining_time = update_time - (Time.new - start)
        if remaining_time > 0 && remaining_count > 0
          sleep_time = remaining_time.to_f / remaining_count
          sleep (sleep_time)
        end
        remaining_count -= 1
  
        eta_printer.increment if options[:show_eta]
      end
    end
    stop = Time.new
    logger.debug("Update cycle took #{stop - start}s, remaining_count is #{remaining_count}")

    if not options[:only_build_directories] and not options[:initial_pass]
      # Set the last_update_finish_time
      server = Earth::Server.this_server
      server.last_update_finish_time = Time.new.utc
      server.save!
    end
    
    total_count
  end

  
private

  @@benchmark_output_enabled = true

  def silent_benchmark
    prev_benchmark_output_enabled = @@benchmark_output_enabled
    @@benchmark_output_enabled = false
    yield
    @@benchmark_output_enabled = prev_benchmark_output_enabled
  end

  def benchmark(description = nil)
    self.status_info = description
    time_before = Time.new
    result = yield
    duration = Time.new - time_before
    if @@benchmark_output_enabled and description
      logger.info "#{description} took #{duration}s"
    end
    result
  end
  
  def initial_pass_on_new_directory(name, parent = nil)
    this_server = Earth::Server.this_server

    benchmark "Scanning and storing tree for #{name}" do
    
      if parent
        directory = parent.children.build(:name => name, :path => "#{parent.path}/#{name}", :server_id => this_server.id)
      else
        directory = this_server.directories.build(:name => name, :path => name)
      end
      directory_count = benchmark "Building initial directory structure for #{name}" do
        update([directory], 0, :only_build_directories => true, :initial_pass => false, :show_eta => false)
      end

      benchmark "Committing initial directory structure for #{name} to database" do
        @directory_eta_printer = ETAPrinter.new(self, "Committing initial directory structure for #{name} to database", directory_count) unless parent
        Earth::Directory.add_save_observer(self) unless parent
        Earth::Directory.cache_enabled = false
        directory.save
        Earth::Directory.cache_enabled = true
        Earth::Directory.remove_save_observer(self) unless parent
        @directory_eta_printer = nil
      end

      directory.reload
      directory.load_all_children

      benchmark "Initial pass at gathering all files beneath #{name}" do
        update([directory], 0, :only_build_directories => false, :initial_pass => true, :show_eta => parent.nil?)
      end

      benchmark "Creating cache information for #{name}" do
        ActiveRecord::Base.logger.debug("begin create cache");
        @cached_size_eta_printer = ETAPrinter.new(self, "Creating cache information for #{name}", directory_count) unless parent
        directory.create_caches_recursively(@cached_size_eta_printer)
        @cached_size_eta_printer = nil
        ActiveRecord::Base.logger.debug("end create cache");
      end

      #benchmark "Vacuuming database" do
      #  Earth::File.connection.update("VACUUM FULL ANALYZE")
      #end

      directory.load_all_children(0)

      directory
    end
  end

  def run(directories, force_update_time=nil)
    # At the beginning of every update get the server information in case it changes on the database
    server = Earth::Server.this_server
    update_time = force_update_time || server.update_interval
    # Hmmm.. children_count doesn't include itself in the count
    directory_count = directories.map{|d| d.children_count + 1}.sum
    if directory_count > 0
      logger.info "Updating #{directory_count} directories over #{update_time}s..."      
      update(directories, update_time)
    else
      logger.warn "No directories monitored"
      self.status_info = "Idle - no directories monitored"
      sleep 2.seconds
    end
  end
  
  def update_non_recursive(directory, options)

    directory_count = 1

    begin
      new_directory_stat = File.lstat(directory.path)
    rescue Errno::ENOENT
      # Handle case when the directory no longer exists
      new_directory_stat = nil

      logger.debug("update_non_recursive for directory #{directory.path} -> removed")
    end
    
    # If directory hasn't changed then return
    if new_directory_stat == directory.stat or \
      (not new_directory_stat.nil? and new_directory_stat.mtime >= 1.seconds.ago)

      if new_directory_stat.nil?
        logger.debug("update_non_recursive for directory #{directory.path} -> just removed")
      elsif new_directory_stat == directory.stat
        logger.debug("update_non_recursive for directory #{directory.path} -> not changed")
      else
        logger.debug("update_non_recursive for directory #{directory.path} -> changed less than 1 second ago (#{new_directory_stat.mtime})")
      end

      return 1
    end


    Earth::Directory::transaction do

      file_names, subdirectory_names, stats = [], [], Hash.new
      if new_directory_stat && new_directory_stat.readable? && new_directory_stat.executable?
        begin
          file_names, subdirectory_names, stats = contents(directory)
        rescue Errno::ENOENT
          # It's possible that the directory was deleted before
          # Dir.entries could be called. Therefore, ignore this
          # exception and treat it like an unreadable directory
        end
      end

      logger.debug("update_non_recursive for directory #{directory.path} -> changed, subdirectories are #{subdirectory_names.inspect}")

      added_directory_names = subdirectory_names - directory.children.map{|x| x.name}
      added_directory_names.each do |name|

        Earth::Directory.benchmark("Creating directory #{directory.path}/#{name}", Logger::DEBUG, !log_all_sql) do
          if options[:only_build_directories] then
            attributes = { :name => name, :path => "#{directory.path}/#{name}", :server_id => directory.server_id }
            dir = directory.children.build(attributes)
            update_non_recursive(dir, options)
          else
            silent_benchmark { initial_pass_on_new_directory(name, directory) }
          end
        end
      end

      if not options[:only_build_directories] then
        # By adding and removing files on the association, the cache of the association will be kept up to date
        if not options[:initial_pass]
          added_file_names = file_names - directory.files.map{|x| x.name}
        else
          added_file_names = file_names
        end
        added_file_names.each do |name|
          Earth::File.benchmark("Creating file with name #{name}", Logger::DEBUG, !log_all_sql) do
            directory.files.create(:name => name, :stat => stats[name])
          end
        end

        if not options[:initial_pass]
          directory_files = directory.files.to_ary.clone
          
          directory_files.each do |file|
            # If the file still exists
            if file_names.include?(file.name)
              logger.debug("checking for update on file #{file.name}")
              # If the file has changed
              if file.stat != stats[file.name]
                file.stat = stats[file.name]
                Earth::File.benchmark("Updating file with name #{file.name}", Logger::DEBUG, !log_all_sql) do
                  file.save
                end
              end
              # If the file has been deleted
            else
              Earth::Directory.benchmark("Removing file with name #{file.name}", Logger::DEBUG, !log_all_sql) do
                directory.files.delete(file)
              end
            end
          end
        end
      end
      
      directory_children = directory.children.to_ary.clone

      directory_children.each do |dir|
        # If the directory has been deleted
        if !subdirectory_names.include?(dir.name)
          
          Earth::Directory.benchmark("Removing directory with name #{dir.name}", Logger::DEBUG, !log_all_sql) do
            directory.child_delete(dir)
          end
        end
      end
      
      # Update the directory stat information at the end
      if not options[:only_build_directories]
        if File.exist?(directory.path) # FIXME - why is this checked again? can this lead to database inconsistency wrt recursive sizes?
          directory.stat = new_directory_stat

          # This will not overwrite 'lft' and 'rgt' so it doesn't matter if these are out of date
          Earth::Directory.benchmark("Updating directory with name #{directory.name}", Logger::DEBUG, !log_all_sql) do
            directory.update
          end

        end
      end
    end
    
    # Removes the files in this directory from the cache (so that they don't take up memory)
    # However, they will get reloaded automatically from the database the next time this
    # directory changes
    directory.files.reset


    directory_count
  end
  
  def contents(directory)
    entries = Dir.entries(directory.path)
    # Ignore ".' and ".." directories
    entries.delete(".")
    entries.delete("..")
    
    # Quote names that can not be converted to UTF8
    quote = QuoteBadCharacters.new
    entries.map!{|text| quote.quote(text)}
    
    # Contains the stat information for both files and directories
    stats = Hash.new
    entries.each do |file| 
      begin
        stats[file] = File.lstat(File.join(directory.path, file))
      rescue Errno::ENOENT
        # It's possible that the file was deleted after the call to
        # Dir.entries and prior to the invocation of
        # File.lstat. Therefore, ignore this exception.
      end
    end
    
    # Seperately test for whether it's a file or a directory because it could
    # be something like a symbolic link (which we shouldn't follow)
    file_names = entries.select{|x| stats.keys.include?(x) and stats[x].file?}
    subdirectory_names = entries.select{|x| stats.keys.include?(x) and stats[x].directory?}
    
    return file_names, subdirectory_names, stats
  end
end
