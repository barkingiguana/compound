module BarkingIguana
  module Compound
    class Environment
      include BarkingIguana::Logging::Helper

      attr_accessor :file
      private :file=, :file

      attr_accessor :overrides
      private :overrides=, :overrides

      def initialize file
        self.file = file
        self.overrides = []
      end

      def merge override
        logger.debug { "ENV registering override: #{override.inspect}" }
        overrides << override
        self
      end

      def to_h
        logger.debug { "ENV evaluating #{file.inspect} (present: #{present?})" }
        h = my_values
        logger.debug { "ENV from #{file.inspect}: #{h.inspect}" }
        overrides.each do |override|
          h.merge! override.to_h
          logger.debug { "ENV after merging #{override.inspect}: #{h.inspect}" }
        end
        logger.debug { "ENV returned from #{file.inspect}: #{h.inspect}" }
        h
      end

      def present?
        File.exists? file
      end

      private

      def my_values
        return {} unless present?
        text = File.read file
        logger.debug { "ENV reading from #{file.inspect}" }
        text.split(/\n/).inject({}) do |env, line|
          name, value = line.split '=', 2
          env[name] = value
          env
        end
      end
    end
  end
end
