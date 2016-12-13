module BarkingIguana
  module Compound
    class Host
      attr_accessor :name, :uri, :state

      def initialize(name:, uri:)
        self.name = name
        self.uri = uri
        self.state = 'unknown'
      end

      def ssh_key
        "#{ENV['HOME']}/.vagrant.d/insecure_private_key"
      end

      def ssh_username
        'vagrant'
      end
    end
  end
end
