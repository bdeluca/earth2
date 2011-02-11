#!/usr/bin/env ruby
#
#  Created by Bruno Mattarollo on 2006-12-21.
#  Copyright (c) 2006. Based on the RedHill Consulting redhillonrails_core
#   plugin. These extensions are to support named Foreign Keys properly.

module RedHillConsulting
  module Core

    module AbstractAdapter

      def add_foreign_key(table_name, column_names, references_table_name, references_column_names, options = {})
        foreign_key = ForeignKeyDefinition.new(column_names, ActiveRecord::Migrator.proper_table_name(references_table_name), references_column_names, options[:on_update], options[:on_delete])
        if options[:name]
          execute "ALTER TABLE #{table_name} ADD CONSTRAINT #{options[:name]} #{foreign_key}"
        else
          execute "ALTER TABLE #{table_name} ADD #{foreign_key}"
        end
      end

    end

    class ForeignKey

      def to_dump
        dump = "add_foreign_key"
        dump << " #{table_name.inspect}, [#{column_names.collect{ |name| name.inspect }.join(', ')}]"
        dump << ", #{references_table_name.inspect}, [#{references_column_names.collect{ |name| name.inspect }.join(', ')}]"
        dump << ", :on_update => :#{on_update}" if on_update
        dump << ", :on_delete => :#{on_delete}" if on_delete
        dump << ", :name => :#{name}" if name
        dump
      end
    end

  end
end
