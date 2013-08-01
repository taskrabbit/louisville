module Louisville
  module CollisionResolvers

    class StringSequence < Abstract
      

      def provides_collision_solution?
        true
      end

      def next_valid_slug
        [next_valid_slug_from_table, next_valid_slug_from_history].compact.sort.last
      end

      protected

      def next_valid_slug_from_table
        length_command  = klass.connection.adapter_name =~ /sqlserver/i ? 'LEN' : 'LENGTH'
        pk_col          = "#{klass.quoted_table_name}.#{klass.primary_key}"
        col             = "#{klass.quoted_table_name}.#{config[:column]}"

        scope  = klass.select("#{col}")
        scope  = scope.where("#{col} LIKE ?", "#{slug_base}%")
        scope  = scope.order("#{length_command}(#{col}) DESC, #{col} DESC")

        return nil unless record = scope.first

        next_slug(record.louisville_slug)
      end


      def next_valid_slug_from_history
        return nil unless using_history? 
        
        scope = Louisville::Util.scope_from(::Louisville::Slug)
        scope = scope.where(:sluggable_type => klass.base_class.sti_name)
        scope = scope.where(:slug_base => slug_base)
        scope = scope.where("#{Louisville::Slug.quoted_table_name}.sluggable_id <> ?", @instance.id) if @instance.persisted?

        "#{slug_base}-#{scope.maximum(:slug_sequence) + 1}"
      end

    end

  end
end