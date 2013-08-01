module Louisville
  module Slugger

    def self.included(base)
      base.extend ClassMethods
      base.class_eval do

        before_validation :apply_louisville_slug
        before_validation :make_louisville_slug_unique, :if => :should_uniquify_louisville_slug?

        validate :validate_louisville_slug
      end
    end

    module ClassMethods

      def slug(field, options = {})
        @louisville_slugger = ::Louisville::Config.new(field, options)
        @louisville_slugger.hook!(self)
        @louisville_slugger
      end

      def louisville_config
        @louisville_slugger || ::Louisville::Config.new
      end

    end

    def louisville_slug
      self.louisville_collision_resolver.read_slug
    end

    def louisville_config
      self.class.louisville_config
    end

    protected


    def louisville_slug=(val)
      self.louisville_collision_resolver.assign_slug(val)
    end

    def louisville_slug_changed?
      self.send("#{louisville_config[:column]}_changed?")
    end

    def apply_louisville_slug
      value = extract_louisville_slug_value_from_field
      value = value.parameterize if value
      self.louisville_slug = value
    end

    def extract_louisville_slug_value_from_field
      self.send(louisville_config[:field])
    end

    def make_louisville_slug_unique
      return if louisville_collision_resolver.unique?

      self.louisville_slug = louisville_collision_resolver.next_valid_slug
    end

    def should_uniquify_louisville_slug?
      louisville_collision_resolver.provides_collision_solution? && self.louisville_slug_changed?
    end

    def validate_louisville_slug
      if self.louisville_slug.blank?
        self.errors.add(louisville_config[:column], :presence)
        return false
      end

      unless louisville_collision_resolver.unique?
        self.errors.add(louisville_config[:column], :uniqueness) 
        return false
      end

      true
    end

  end
end