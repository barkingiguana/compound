module BarkingIguana
  module Compound
    class Host
      extend Forwardable

      attr_accessor :inventory_name, :ip_address, :state

      def initialize(name:, ip_address:)
        self.inventory_name = name
        self.ip_address = ip_address
        self.state = 'unknown'
      end

      def name
        @name ||= inventory_name.gsub(/[^a-z0-9\-]/, '-')
      end

      def <=> other
        name <=> other.name
      end
      include Comparable

      def assign_ip_address new_ip_address
        self.ip_address = new_ip_address
      end

      def ssh_key
        "#{ENV['HOME']}/.vagrant.d/insecure_private_key"
      end

      def ssh_username
        'vagrant'
      end

      def ssh_extra_args
        '-o StrictHostKeyChecking=no'
      end

      def_delegator :inventory_name, :hash

      def eql? other
        inventory_name == other.inventory_name
      end
    end
  end
end
