module BarkingIguana
  module Compound
    class TestSuite
      def self.define_rake_tasks
        new.define_rake_tasks
      end

      def define_rake_tasks
        Rake::Task.define_task name do
          run
        end.add_description "Run #{name} suite"

        tests.each do |test|
          Rake::Task.define_task "#{name}:#{test.name}" do
            test.run
          end.add_description "Run #{test.name} test from #{name} suite"

          test.stages.each do |stage|
            Rake::Task.define_task "#{name}:#{test.name}:#{stage.name}" do
              stage.run
            end.add_description "Run #{stage.name} stage of the #{test.name} test from #{name} suite"
            stage.actions.each do |action|
              Rake::Task.define_task "#{name}:#{test.name}:#{stage.name}:#{action}" do
                stage.public_send action
              end.add_description "Run action #{action} for #{stage.name} stage of the #{test.name} test from #{name} suite"
            end
          end

          Rake::Task.define_task "#{name}:#{test.name}:destroy" do
            test.teardown
          end.add_description "Tear down #{test.name} test from #{name} suite"
        end
      end

      attr_accessor :control_directory
      private :control_directory=

      attr_accessor :directory
      private :directory=

      def initialize(directory = nil, control_directory: nil)
        self.control_directory = control_directory || guess_directory
        self.directory = directory || File.expand_path("test/compound", control_directory)
      end

      def guess_directory
        caller.detect do |trace|
          path = trace.split(/:/, 2)[0]
          file = File.basename path
          break File.dirname path if file == 'Rakefile'
        end
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
