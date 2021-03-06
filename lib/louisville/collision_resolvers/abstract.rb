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


      def slug_changed?
        @instance.send("#{config[:column]}_changed?")
      end



      protected



      def slug_base(compare = nil)
        Louisville::Util.slug_base(compare || @instance.louisville_slug.to_s)
      end


      def slug_sequence(compare = nil)
        Louisville::Util.slug_sequence(compare || @instance.louisville_slug.to_s)
      end



      def unique_in_history?
        return true unless config.option?(:history)

        scope = ::Louisville::Slug.where(:sluggable_type => ::Louisville::Util.polymorphic_name(klass))
        scope = scope.where(:slug_base => slug_base)
        scope = scope.where(:slug_sequence => slug_sequence)
        scope = scope.where("#{Louisville::Slug.quoted_table_name}.sluggable_id <> ?", @instance.id) if @instance.persisted?

        !scope.exists?
      end


      def unique_in_table?
        scope = klass.where(config[:column] => @instance.louisville_slug)
        scope = scope.where("#{klass.quoted_table_name}.#{klass.primary_key} <> ?", @instance.id) if @instance.persisted?

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


      def provide_latest_slug(*slugs)
        slugs.compact.sort{|a,b| a.length == b.length ? a <=> b : a.length - b.length }.last
      end

    end
  end
end
