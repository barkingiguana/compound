module BarkingIguana
  module Compound
    class TestStage
      attr_accessor :test, :stage_directory

      def initialize test, stage_directory
        self.test = test
        self.stage_directory = stage_directory
      end

      def actions
        %i(setup converge verify).freeze
      end

      include BarkingIguana::Logging::Helper
      include BarkingIguana::Benchmark

      def run
        benchmark display_name do
          actions.each do |action|
            benchmark "#{display_name} action #{action}" do
              public_send action
            end
          end
        end
      end

      def name
        directory
      end

      def display_name
        test.name + ' stage ' + stage_directory
      end

      def inventory_path
        stage_file_with_fallback 'inventory'
      end

      def stage_file_with_fallback file_name
        stage_file = File.expand_path file_name, stage_directory
        return stage_file if File.exists? stage_file
        File.expand_path file_name, test.directory
      end

      def playbook_path
        stage_file_with_fallback 'playbook.yml'
      end

      def inventory
        Ansible.inventory inventory_path
      end

      def hosts
        inventory.hosts
      end

      def control_directory
        test.suite.control_directory
      end

      def playbook
        Ansible.playbook(playbook_path, run_from: control_directory).inventory(inventory.path).private_key("#{ENV['HOME']}/.vagrant.d/insecure_private_key").user('vagrant').stream_to(logger).verbosity(2).diff
      end

      def suite
        test.suite
      end

      def setup
        desired_hosts = inventory.hosts.map { |h| h.name  }.sort
        logger.debug { "Desired hosts for #{display_name}: #{desired_hosts.join(', ')}" }
        active_hosts = host_manager.active.map { |h| h.name }.sort
        logger.debug { "Active hosts for #{display_name}: #{active_hosts.join(', ')}" }
        hosts_to_launch = desired_hosts - active_hosts
        logger.debug { "Launch hosts for #{display_name}: #{hosts_to_launch.join(', ')}" }
        host_manager.launch *hosts_to_launch
        hosts_to_stop = active_hosts - desired_hosts
        logger.debug { "Stop hosts for #{display_name}: #{hosts_to_stop.join(', ')}" }
        host_manager.shutdown *hosts_to_stop
      end

      def host_manager
        test.host_manager
      end

      def converge
        return unless File.exists? playbook_path
        playbook.run
      end

      def verify
        server_spec.run
      end

      def server_spec
        @server_spec ||= ServerSpec.new(self)
      end
    end
  end
end
