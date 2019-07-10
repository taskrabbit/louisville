#
# The finder extension allows your class to use find('slug') to query for your record.
# If the history extension is enabled it will also query the history table to see if
# there are any previous slugs that match.
#
# The finder option is enabled by default, to disable provide `finder: false` to your slug() invocation.
# No options are used.
#

module Louisville
  module Extensions
    module Finder


      def self.included(base)
        base.extend ClassMethods
        base.class_eval do
          class << self
            alias_method_chain :relation, :louisville_finder

            if ActiveRecord::VERSION::MAJOR >= 4 && ActiveRecord::VERSION::MINOR >= 2
              alias_method_chain :find, :louisville_finder
            end

          end
        end
      end



      module ClassMethods

        def find_with_louisville_finder(*args)
          return find_without_louisville_finder(*args) if args.length != 1

          id = args[0]
          id = id.id if ActiveRecord::Base === id

          if id.is_a?(String) && !Louisville::Util.numeric?(id)
            relation_with_louisville_finder.find_one(id)
          else
            find_without_louisville_finder(*args)
          end
        end

        private

        def relation_with_louisville_finder
          rel = relation_without_louisville_finder
          rel.extend RelationMethods
          rel
        end
      end



      module RelationMethods


        def find_one(id)
          id = id.id if ActiveRecord::Base === id

          return super(id) if Louisville::Util.numeric?(id)

          seq_column = "#{louisville_config[:column]}_sequence"

          if self.column_names.include?(seq_column)
            base, seq = Louisville::Util.slug_parts(id)
            record = self.where(louisville_config[:column] => base, seq_column => seq).first
          else
            record = self.where(louisville_config[:column] => id).first
          end

          return record if record

          if louisville_config.option?(:history)

            base, seq = Louisville::Util.slug_parts(id)

            record = Louisville::Slug.where(:slug_base => base, :slug_sequence => seq, :sluggable_type => ::Louisville::Util.polymorphic_name(self)).select(:sluggable_id).first
            super(record.try(:sluggable_id) || id)
          else
            return super(id)
          end
        end


        def exists?(id = :none)
          id = id.id if ActiveRecord::Base === id

          return super(id) if Louisville::Util.numeric?(id)

          if String === id
            return true       if super(louisville_config[:column] => id)
            return super(id)  unless louisville_config.option?(:history)

            base, seq = Louisville::Util.slug_parts(id)

            Louisville::Slug.where(:slug_base => base, :slug_sequence => seq, :sluggable_type => ::Louisville::Util.polymorphic_name(name)).exists?

          elsif ActiveRecord::VERSION::MAJOR == 3
            return super(id == :none ? false : id)
          else
            return super(id)
          end
        end

      end

    end
  end
end
