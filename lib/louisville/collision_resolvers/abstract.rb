module Louisville
  module CollisionResolvers
    class Abstract

      def initialize(instance, options = {})
        @instance = instance
        @options  = options
      end

      def unique?
        unique_in_table? && unique_in_history?
      end

      def next_valid_slug
        raise NotImplementedError
      end

      def provides_collision_solution?
        false
      end

      def assign_slug(val)
        @instance.send("#{config[:column]}=", val)
      end

      def read_slug
        @instance.send(config[:column])
      end

      def slug_base(compare = nil)
        Louisville::Util.slug_base(compare || @instance.louisville_slug.to_s)
      end

      def slug_sequence(compare = nil)
        Louisville::Util.slug_sequence(compare || @instance.louisville_slug.to_s)
      end

      protected

      def using_history?
        config.option?(:history)
      end

      def unique_in_history?
        return true unless using_history?
        
        scope = Louisville::Util.scope_from(::Louisville::Slug)
        scope = scope.where(:sluggable_type => klass.base_class.sti_name)
        scope = scope.where(:slug_base => slug_base)
        scope = scope.where(:slug_sequence => slug_sequence)
        scope = scope.where("#{Louisville::Slug.quoted_table_name}.sluggable_id <> ?", @instance.id) if @instance.persisted?

        !scope.exists?
      end

      def unique_in_table?
        scope = Louisville::Util.scope_from(klass)
        scope = scope.where("#{klass.quoted_table_name}.#{klass.primary_key} <> ?", @instance.id) if @instance.persisted?
        scope = scope.where(config[:column] => @instance.louisville_slug)

        !scope.exists?
      end


      def config
        @instance.louisville_config
      end

      def klass
        @instance.class
      end

      def next_slug(slug)

        base      = slug_base(slug)
        sequence  = slug_sequence(slug)

        "#{base}--#{sequence + 1}"
      end

    end
  end
end