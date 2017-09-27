module BarkingIguana
  module Compound
    class TestStage
      extend Forwardable

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

      def extra_vars?
        File.exists? extra_vars_path
      end

      def extra_vars_path
        @extra_vars_path ||= stage_file_with_fallback('extra_vars.json')
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

      def tmp_dir *sub_path
        @tmp_dir ||= Dir.mktmpdir
        return @tmp_dir if sub_path.empty?
        full_path = File.expand_path File.join(sub_path), @tmp_dir
        FileUtils.mkdir_p full_path
        full_path
      end

      def generate_inventory
        benchmark "#{name}: generating inventory for test stage" do
          tmp_dir('inventory').tap do |d|
            logger.debug { "#{name}: inventory directory is #{d.inspect}" }
            connection_file = File.expand_path 'connection', d
            Ansible::InventoryWriter.new(connection_file).tap do |i|
              benchmark "#{name}: generating connection inventory at #{connection_file}" do
                test_hosts = test.host_manager.find_all_by_name hosts.map(&:inventory_name)
                test_hosts.each do |h|
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

      def ansible_verbosity
        return 2 unless ENV['ANSIBLE_VERBOSITY']
        ENV['ANSIBLE_VERBOSITY'].to_i
      end

      def playbook
        Ansible.playbook(playbook_path, run_from: control_directory).tap { |p|
          p.inventory(generated_inventory)
          p.stream_to(playbook_logger)
          p.verbosity(ansible_verbosity)
          p.diff
          p.extra_vars extra_vars_path if extra_vars?
        }
      end

      def playbook_logger
        @playbook_logger ||= BarkingIguana::ForkCalls.fork_to(logger, results_logger)
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

      def converge
        unless File.exists? playbook_path
          logger.debug { "Not running anything because #{playbook_path.inspect} does not exist" }
          return
        end
        playbook.run
      ensure
        logger.debug { "Removing generated inventory from #{generated_inventory}" }
        FileUtils.rm_r generated_inventory
      end

      def clean_up
        logger.debug { "Removing temporary directory for stage #{name} from #{tmp_dir}" }
        FileUtils.rm_r tmp_dir
      end

      def_delegator :original_inventory, :hosts
      def_delegator :test, :suite
      def_delegator :test, :host_manager
      def_delegator :suite, :control_directory

      def verify
        server_spec.run
        ansible_spec.run
      end

      def results_file
        @results_file ||= File.expand_path('playbook.out', tmp_dir('results', 'ansible'))
      end

      private

      def server_spec
        @server_spec ||= ServerSpec.new(self)
      end

      def ansible_spec
        @ansible_spec ||= AnsibleSpec.new(self)
      end

      def results_logger
        @results_logger ||= ::Logger.new(results_file).tap do |l|
          l.level = ::Logger::DEBUG
          l.formatter = lambda { |_, _, _, message| message }
        end
      end
    end
  end
end
