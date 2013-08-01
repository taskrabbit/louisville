module Louisville
  module CollisionResolvers

    class NumericSequence < Abstract
      

      def provides_collision_solution?
        true
      end

      def next_valid_slug
        [next_valid_slug_from_table, next_valid_slug_from_history].compact.sort.last
      end

      def assign_slug(val)
        base, seq = Louisville::Util.slug_parts(val)

        @instance.send("#{config[:column]}=", base)
        @instance.send("#{config[:column]}_sequence=", seq)
      end

      def read_slug
        col = config[:column]
        seq = "#{col}_sequence"

        "#{@instance.send(col)}--#{@instance.send(seq)}"
      end

      protected

      def unique_in_table?

        base_method     = config[:column]
        sequence_method = "#{config[:column]}_sequence"

        scope = Louisville::Util.scope_from(klass)
        scope = scope.where("#{klass.quoted_table_name}.#{klass.primary_key} <> ?", @instance.id) if @instance.persisted?
        scope = scope.where(config[:column] => @instance.send(base_method), sequence_method => @instance.send(sequence_method))

        !scope.exists?
      end

      def next_valid_slug_from_table
        base_field = config[:column]
        sequ_field = "#{config[:column]}_sequence"

        scope = Louisville::Util.scope_from(klass)
        scope = scope.where(base_field => slug_base)
        scope = scope.where("#{klass.quoted_table_name}.#{klass.primary_key} <> ?", @instance.id) if @instance.persisted?

        "#{slug_base}--#{scope.maximum(sequ_field).to_i + 1}"
      end


      def next_valid_slug_from_history
        return nil unless using_history?
        
        scope = Louisville::Util.scope_from(::Louisville::Slug)
        scope = scope.where(:sluggable_type => klass.base_class.sti_name)
        scope = scope.where(:slug_base => slug_base)
        scope = scope.where("#{Louisville::Slug.quoted_table_name}.sluggable_id <> ?", @instance.id) if @instance.persisted?

        "#{slug_base}--#{scope.maximum(:slug_sequence).to_i + 1}"
      end

    end

  end
end