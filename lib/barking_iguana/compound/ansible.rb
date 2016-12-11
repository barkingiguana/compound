module BarkingIguana
  module Compound
    module Ansible
      def self.inventory *args
        Inventory.new *args
      end

      def self.playbook *args
        Playbook.new *args
      end
    end
  end
end
