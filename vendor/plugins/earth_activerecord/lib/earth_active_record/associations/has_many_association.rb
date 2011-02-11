module EarthActiveRecord
  module Associations
    module HasManyAssociation
      def self.included(base)
        base.class_eval do
          alias_method_chain :delete_records, :earth_modifications
        end
      end

      def delete_records_with_earth_modifications(records)
        if @reflection.options[:dependent].nil? || @reflection.options[:dependent] == :nullify
          ids = quoted_record_ids(records)
          @reflection.klass.update_all(
            "#{@reflection.primary_key_name} = NULL", 
            "#{@reflection.primary_key_name} = #{@owner.quoted_id} AND #{@reflection.klass.primary_key} IN (#{ids})"
          )
        elsif @reflection.options[:dependent] == :destroy
          records.each { |r| r.destroy }
        elsif @reflection.options[:dependent] == :delete_all || @reflection.options[:dependent] == :delete_cascade
          @reflection.klass.delete(records.map{|r| r.id})
        end
      end
    end
  end
end
