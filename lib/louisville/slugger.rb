module Louisville
  module Slugger

    def self.included(base)
      base.extend ClassMethods
      base.class_eval do

        before_validation :apply_louisville_slug

        validate :validate_louisville_slug, :if => :needs_to_validate_louisville_slug?
      end
    end



    module ClassMethods

      def slug(field, options = {})
        @louisville_slugger = ::Louisville::Config.new(field, options)
        @louisville_slugger.hook!(self)
        @louisville_slugger
      end

      def louisville_config
        @louisville_slugger || (superclass.respond_to?(:louisville_config) ? superclass.louisville_config : nil)
      end

    end



    def louisville_slug
      self.send(louisville_config[:column])
    end


    def louisville_config
      self.class.louisville_config
    end



    protected



    def louisville_slug=(val)
      self.send("#{louisville_config[:column]}=", val)
    end


    def louisville_slug_changed?
      self.send("#{louisville_config[:column]}_changed?")
    end

    def louisville_slug_previously_changed?
      self.send("#{louisville_config[:column]}_previously_changed?")
    end

    def apply_louisville_slug
      value = extract_louisville_slug_value_from_field
      value = sanitize_louisville_slug(value) if value

      # the value may have changed but the parameterized value may be the same
      # charlie vs Charlie.
      if self.louisville_slug
        base = Louisville::Util.slug_base(self.louisville_slug)

        # if the base hasn't changed let's not set the value since doing so may incur extra cost.
        # namely, the numeric_sequence resolver would have to determine and apply the sequence.
        if base != value
          self.louisville_slug = value
        end

      else
        self.louisville_slug = value
      end
    end


    def sanitize_louisville_slug(value)
      value.parameterize
    end


    def extract_louisville_slug_value_from_field
      self.send(louisville_config[:field])
    end


    def validate_louisville_slug

      if louisville_slug.blank?
        errors.add(louisville_config[:column], :blank)
        return false
      end

      true
    end

    def needs_to_validate_louisville_slug?
      new_record? || louisville_slug_changed?
    end

  end
end
