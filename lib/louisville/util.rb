module Louisville
  class Util

    SLUG_MATCHER = /^(.+)--([\d]+)$/

    class << self

      def slug_base(compare)
        compare =~ SLUG_MATCHER
        $1 || compare
      end

      def slug_sequence(compare)
        compare =~ SLUG_MATCHER
        [$2.to_i, 1].max
      end

      def slug_parts(compare)
        [slug_base(compare), slug_sequence(compare)]
      end

      def scope_from(a_class)
        if ActiveRecord::VERSION::MAJOR == 3
          a_class.scoped
        else
          a_class.all
        end
      end

    end

  end
end