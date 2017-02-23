require 'active_record'
require 'active_record/associations'
module ActiveRecord
  module Associations
    module ClassMethods
      def has_and_belongs_to_many(name, scope = nil, options = {}, &extension)
        if scope.is_a?(Hash)
          options = scope
          scope   = nil
        end

        habtm_reflection = ActiveRecord::Reflection::HasAndBelongsToManyReflection.new(name, scope, options, self)

        builder = Builder::HasAndBelongsToMany.new name, self, options

        join_model = builder.through_model

        const_set join_model.name, join_model
        private_constant join_model.name

        middle_reflection = builder.middle_reflection join_model

        Builder::HasMany.define_callbacks self, middle_reflection
        Reflection.add_reflection self, middle_reflection.name, middle_reflection
        middle_reflection.parent_reflection = habtm_reflection

        include Module.new {
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def destroy_associations
            if !self.class.connection.is_a?(ActiveRecord::ConnectionAdapters::SunstoneAPIAdapter)
              association(:#{middle_reflection.name}).delete_all(:delete_all)
              association(:#{name}).reset
            end
            super
          end
          RUBY
        }

        hm_options = {}
        hm_options[:through] = middle_reflection.name
        hm_options[:source] = join_model.right_reflection.name

        [:before_add, :after_add, :before_remove, :after_remove, :autosave, :validate, :join_table, :class_name, :extend].each do |k|
          hm_options[k] = options[k] if options.key? k
        end

        has_many name, scope, hm_options, &extension
        self._reflections[name.to_s].parent_reflection = habtm_reflection
      end
    end
  end
end