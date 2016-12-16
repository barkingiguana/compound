module BarkingIguana
  module Compound
    class TestSuite
      def define_rake_tasks
        Rake::Task.define_task name do
          run
        end.add_description "Run #{name} suite"

        tests.each do |test|
          Rake::Task.define_task "#{name}:#{test.name}" do
            test.run
          end.add_description "Run #{test.name} test from #{name} suite"

          Rake::Task.define_task "#{name}:#{test.name}:destroy" do
            test.teardown
          end.add_description "Tear down #{test.name} test from #{name} suite"
        end
      end

      attr_accessor :control_directory
      private :control_directory=

      attr_accessor :directory
      private :directory=

      def initialize directory, control_directory
        self.directory = directory
        self.control_directory = control_directory
      end

      def tests
        test_directories.map { |d| Test.new self, d }
      end

      def name
        File.basename directory
      end

      include BarkingIguana::Logging::Helper
      include BarkingIguana::Benchmark

      def run
        benchmark name do
          tests.each &:run
        end
      end

      private

      def test_directories
        Dir.glob("#{directory}/*").select { |d| File.directory? d }
      end
    end
  end
end
