module EarthActiveRecord
  module Associations
    module AssociationCollection #:nodoc:
      def self.included(base)
        base.class_eval do
          alias_method_chain :delete, :earth_modifications
        end
      end
    
      # Remove +records+ from this association. What it does with the associated record
      # is set by :dependent
      def delete_with_earth_modifications(*records)
        records = flatten_deeper(records)
        records.each { |record| raise_on_type_mismatch(record) }
        records.reject! { |record| @target.delete(record) if record.new_record? }
        return if records.empty?
        
        @owner.transaction do
          records.each { |record| callback(:before_remove, record) }
          delete_records(records)
          records.each do |record|
            @target.delete(record)
            callback(:after_remove, record)
          end
        end
      end
    end
  end
end
