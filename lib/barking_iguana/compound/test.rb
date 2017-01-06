module BarkingIguana
  module Compound
    class Test
      attr_accessor :suite
      private :suite=

      attr_accessor :directory
      private :directory=

      include BarkingIguana::Logging::Helper
      include BarkingIguana::Benchmark

      def initialize suite, directory
        self.suite = suite
        self.directory = directory
      end

      def name
        directory.sub(suite.directory + '/', '').tr('/', ':')
      end

      def stages
        Dir[directory + '/*'].select { |d| File.directory? d }.map { |s| TestStage.new self, File.basename(s) }
      end

      def run
        benchmark "test #{name}" do
          begin
            logger.debug { "#{name}: found #{stages.size} stages: #{stages.map(&:name).map(&:inspect).join(', ')}" }
            stages.each &:run
          ensure
            teardown
          end
        end
      end

      def teardown
        benchmark "#{name}: destroying all hosts" do
          host_manager.destroy_all
        end
        return unless custom_teardown?
        command_line = "bash -ex #{custom_teardown_file}"
        c = Mixlib::ShellOut.new command_line, cwd: directory, live_stream: logger
        benchmark "#{name}: running custom teardown" do
          c.run_command
        end
        c.error!
      end

      def custom_teardown?
        File.exists? custom_teardown_file
      end

      def custom_teardown_file
        File.expand_path "teardown.sh", directory
      end

      def host_manager
        @host_manger ||= begin
          # FIXME: Implement uniqueness operators on Host
          hosts = stages.map(&:hosts).flatten.uniq(&:ip_address).sort
          HostManager.new(hosts, driver_options)
        end
      end

      def test_file_with_fallback file_name
        logger.debug { "Searching for #{file_name.inspect}" }
        test_file = File.expand_path file_name, directory
        logger.debug { "Checking #{test_file.inspect}" }
        if File.exists? test_file
          logger.debug { "Found #{file_name.inspect} at #{test_file.inspect}" }
          return test_file
        end
        suite_file = File.expand_path file_name, suite.directory
        logger.debug { "Assuming it'll be at #{suite_file.inspect}" }
        suite_file
      end

      def driver_options
        options = {}
        logger.debug { "Does #{vagrant_file_template_path} exist? -> #{File.exists? vagrant_file_template_path}" }
        options[:vagrant_file_template_path] = vagrant_file_template_path if File.exists? vagrant_file_template_path
        options[:root] = directory
        options[:environment] = suite.environment.merge environment
        options
      end

      def environment_file
        File.join directory, 'env'
      end

      def environment
        @environment ||= Environment.new(environment_file)
      end

      def vagrant_file_template_path
        test_file_with_fallback 'Vagrantfile.erb'
      end

      def hosts
        host_manager.all
      end
    end
  end
end
