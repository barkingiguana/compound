module BarkingIguana
  module Compound
    class CommandLineClient
      attr_accessor :argv
      private :argv=, :argv

      def initialize argv
        self.argv = argv
      end

      def run
        # TODO: Make it possible to select the test to run if desired
        test_suite.run
      end

      def test_suite
        @test_suite ||= TestSuite.new('test/compound', control_directory: working_directory)
      end

      def working_directory
        Dir.pwd
      end
    end
  end
end
