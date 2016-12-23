module BarkingIguana
  module Compound
    class HostManager
      attr_accessor :hosts
      private :hosts=

      attr_accessor :implementation
      private :implementation=, :implementation

      include BarkingIguana::Logging::Helper
      include BarkingIguana::Benchmark

      def initialize hosts = [], implementation_options = {}
        self.hosts = hosts
        self.implementation = Vagrant.new self, implementation_options
        implementation.prepare
      end

      def destroy_all
        destroy *hosts.map { |h| h.name }
      end

      def active
        all.select { |h| h.state == 'running' }
      end

      def all
        refresh_status
        hosts
      end

      def refresh_status
        benchmark "refreshing host status" do
          implementation.refresh_status
        end
      end

      {
        launch: "up",
        shutdown: "halt",
        destroy: "destroy",
      }.each do |interface, command|
        define_method interface do |*host_names|
          if host_names.empty?
            logger.debug { "Not running anything because the hosts list is empty" }
          else
            host_names.sort!
            benchmark "running #{interface} for #{host_names.join(', ')}" do
              implementation.public_send command, *host_names
            end
          end
        end
      end

      def find_by_name name
        all.detect { |h| h.name == name }
      end
    end
  end
end
