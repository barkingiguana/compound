module BarkingIguana
  module Compound
    class TestStage
      attr_accessor :test, :directory

      def initialize test, directory
        self.test = test
        self.directory = directory
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
        test.name + ' stage ' + directory
      end

      def inventory_path
        @inventory_path ||= stage_file_with_fallback('inventory')
      end

      def stage_directory
        File.expand_path directory, test.directory
      end

      def stage_file_with_fallback file_name
        logger.debug { "Searching for #{file_name.inspect}" }
        stage_file = File.expand_path file_name, stage_directory
        logger.debug { "Checking #{stage_file.inspect}" }
        if File.exists? stage_file
          logger.debug { "Found #{file_name.inspect} at #{stage_file.inspect}" }
          return stage_file
        end
        test_file = File.expand_path file_name, test.directory
        logger.debug { "Assuming it'll be at #{test_file.inspect}" }
        test_file
      end

      def playbook_path
        @playbook_path ||= stage_file_with_fallback('playbook.yml')
      end

      def original_inventory
        @original_inventory ||= Ansible.inventory(inventory_path)
      end

      def generated_inventory
        @generated_inventory ||= generate_inventory
      end

      def generate_inventory
        benchmark "#{name}: generating inventory for test stage" do
          Dir.mktmpdir('inventory').tap do |d|
            logger.debug { "#{name}: inventory directory is #{d.inspect}" }
            connection_file = File.expand_path 'connection', d
            Ansible::InventoryWriter.new(connection_file).tap do |i|
              benchmark "#{name}: generating connection inventory at #{connection_file}" do
                hosts.each do |host|
                  h = test.host_manager.find_by_name host.inventory_name
                  i.add_host h
                end
                logger.debug { "#{name}: writing connection inventory:\n#{i.to_s}" }
                i.write_file
              end
            end
            original_file = File.expand_path 'original', d
            logger.debug { "#{name}: copying original inventory to #{original_file} from #{inventory_path}" }
            FileUtils.copy inventory_path, original_file
          end
        end
      end

      def hosts
        original_inventory.hosts
      end

      def control_directory
        test.suite.control_directory
      end

      def ansible_verbosity
        return 2 unless ENV['ANSIBLE_VERBOSITY']
        ENV['ANSIBLE_VERBOSITY'].to_i
      end

      def playbook
        Ansible.playbook(playbook_path, run_from: control_directory).inventory(generated_inventory).stream_to(logger).verbosity(ansible_verbosity).diff
      end

      def suite
        test.suite
      end

      def setup
        desired_hosts = hosts.sort.map(&:name)
        logger.debug { "Desired hosts for #{display_name}: #{desired_hosts.join(', ')}" }
        active_hosts = host_manager.active.sort.map(&:name)
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
        unless File.exists? playbook_path
          logger.debug { "Not running anything because #{playbook_path.inspect} does not exist" }
          return
        end
        playbook.run
      ensure
        logger.debug { "Removing generated inventory from #{generated_inventory}" }
        # FileUtils.rm_r generated_inventory
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
