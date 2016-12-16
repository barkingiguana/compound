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
        @host_manger ||= HostManager.new(hosts, driver_options)
      end

      def driver_options
        options = {}
        logger.debug { "Does #{vagrant_file_template_path} exist? -> #{File.exists? vagrant_file_template_path}" }
        options[:vagrant_file_template_path] = vagrant_file_template_path if File.exists? vagrant_file_template_path
        options[:root] = directory
        options
      end

      def vagrant_file_template_path
        File.join directory, 'Vagrantfile.erb'
      end

      def hosts
        # FIXME: Implement uniqueness operators on Host
        stages.map(&:hosts).flatten.uniq { |h| h.uri }
      end
    end
  end
end
