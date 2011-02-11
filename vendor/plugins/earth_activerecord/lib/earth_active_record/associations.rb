module EarthActiveRecord
  module Associations # :nodoc:
    module ClassMethods
      def self.included(base)
        base.class_eval do
          alias_method_chain :configure_dependency_for_has_many, :earth_modifications
        end
      end
      
      def configure_dependency_for_has_many_with_earth_modifications(reflection)
        if reflection.options[:dependent] == true
          ::ActiveSupport::Deprecation.warn("The :dependent => true option is deprecated and will be removed from Rails 2.0.  Please use :dependent => :destroy instead.  See http://www.rubyonrails.org/deprecation for details.", caller)
        end

        if reflection.options[:dependent] && reflection.options[:exclusively_dependent]
          raise ArgumentError, ':dependent and :exclusively_dependent are mutually exclusive options.  You may specify one or the other.'
        end

        if reflection.options[:exclusively_dependent]
          reflection.options[:dependent] = :delete_all
          ::ActiveSupport::Deprecation.warn("The :exclusively_dependent option is deprecated and will be removed from Rails 2.0.  Please use :dependent => :delete_all instead.  See http://www.rubyonrails.org/deprecation for details.", caller)
        end

        # See HasManyAssociation#delete_records.  Dependent associations
        # delete children, otherwise foreign key is set to NULL.

        # Add polymorphic type if the :as option is present
        dependent_conditions = %(#{reflection.primary_key_name} = \#{record.quoted_id})
        if reflection.options[:as]
          dependent_conditions += " AND #{reflection.options[:as]}_type = '#{base_class.name}'"
        end

        case reflection.options[:dependent]
          when :destroy, true
            module_eval "before_destroy '#{reflection.name}.each { |o| o.destroy }'"
          when :delete_all
            module_eval "before_destroy { |record| #{reflection.class_name}.delete_all(%(#{dependent_conditions})) }"
          when :nullify
            module_eval "before_destroy { |record| #{reflection.class_name}.update_all(%(#{reflection.primary_key_name} = NULL),  %(#{dependent_conditions})) }"
          when :delete_cascade, nil, false
            # pass
          else
            raise ArgumentError, 'The :dependent option expects either :destroy, :delete_all, :nullify, or :delete_cascade'
        end
      end
    end
  end
end


 