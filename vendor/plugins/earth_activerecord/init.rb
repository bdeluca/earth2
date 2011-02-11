ActiveRecord::Associations::ClassMethods.send(:include, EarthActiveRecord::Associations::ClassMethods)
ActiveRecord::Associations::AssociationCollection.send(:include, EarthActiveRecord::Associations::AssociationCollection)
ActiveRecord::Associations::HasManyAssociation.send(:include, EarthActiveRecord::Associations::HasManyAssociation)
