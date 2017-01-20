module BarkingIguana
  module Compound
    class AnsibleSpec
      extend Forwardable
      attr_accessor :stage

      def initialize stage
        self.stage = stage
      end

      include BarkingIguana::Logging::Helper
      include BarkingIguana::Benchmark

      def run
        unless File.exists? ansible_test_directory
          logger.debug { "#{ansible_test_directory} doesn't exist, assuming no ansible tests for this stage" }
          return
        end

        command = "bundle exec ruby -S rspec -r #{spec_helper} #{test_files.join(' ')}"
        c = Mixlib::ShellOut.new command, live_stream: logger, cwd: control_repo_dir, env: env
        benchmark command do
          c.run_command
        end
        logger.info { "ansible tests exited with status #{c.exitstatus}" }
        c.error!
      end

      private

      def test_files
        Dir.glob File.expand_path '**/*_spec.rb', ansible_test_directory
      end

      def env
        {
          ANSIBLE_RESULTS_FILE: ansible_results_file
        }
      end

      def spec_helper
        File.expand_path '../../../../resources/ansible_spec_helper.rb', __FILE__
      end

      def ansible_test_directory
        File.expand_path '_ansible', root_dir
      end

      def_delegator :stage, :test
      def_delegator :stage, :stage_directory, :root_dir
      def_delegator :stage, :results_file, :ansible_results_file
      def_delegator :test, :suite
      def_delegator :suite, :control_directory, :control_repo_dir
    end
  end
end
