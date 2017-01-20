module BarkingIguana
  module Compound
    class ServerSpec
      extend Forwardable
      attr_accessor :stage

      def initialize stage
        self.stage = stage
      end

      include BarkingIguana::Logging::Helper
      include BarkingIguana::Benchmark

      def run
        logger.debug { "Host tests: #{host_tests.inspect}" }
        host_tests.each do |host, test_files|
          command = "bundle exec ruby -S rspec -r #{spec_helper} #{test_files.join(' ')}"
          c = Mixlib::ShellOut.new command, live_stream: logger, cwd: control_repo_dir, env: env_for(host)
          benchmark command do
            c.run_command
          end
          logger.info { "#{host.name} tests exited with status #{c.exitstatus}" }
          c.error!
        end
      end

      def env_for host
        {
          TARGET_HOST: host.ip_address,
          TARGET_SSH_USER: host.ssh_username,
          TARGET_SSH_KEY: host.ssh_key
        }
      end

      def host_tests
        hosts.inject({}) do |a,e|
          name = e.name
          glob = "#{root_dir}/#{name}/**/*_spec.rb"
          logger.debug { "Host glob for #{name.inspect} = #{glob.inspect}" }
          tests = Dir.glob glob
          logger.debug { "Host tests for #{name.inspect} = #{tests.inspect}" }
          if !tests.empty?
            if e.state != 'running'
              raise "There are tests for #{name} in #{stage.stage_directory}, but the host is #{e.state}"
            end
            a[e] = tests
          end
          a
        end
      end

      def spec_helper
        File.expand_path '../../../../resources/server_spec_helper.rb', __FILE__
      end

      def_delegator :stage, :test
      def_delegator :stage, :stage_directory, :root_dir
      def_delegator :test, :suite
      def_delegator :suite, :control_directory, :control_repo_dir
      def_delegator :test, :host_manager
      def_delegator :host_manager, :all, :hosts
    end
  end
end
