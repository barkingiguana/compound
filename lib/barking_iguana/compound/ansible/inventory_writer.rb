module BarkingIguana
  module Compound
    module Ansible
      class InventoryWriter
        include BarkingIguana::Logging::Helper

        attr_accessor :path
        private :path=

        attr_accessor :hosts
        private :hosts=, :hosts

        def initialize path = nil
          self.path = path || generate_random_filename
          self.hosts = []
        end

        def add_host host
          hosts << host
          hosts.uniq! &:ip_address
        end

        def generate_random_filename
          name = [
            'inventory',
            Process.pid,
            Time.now.to_i,
            rand(9_999_999_999).to_s.rjust(10, '0')
          ].join('-')
        end

        def write_file
          File.open path, 'w' do |inventory|
            inventory.puts to_s
          end
        end

        def to_s
          hosts.sort_by(&:name).map do |h|
            %Q(#{h.inventory_name} ansible_host=#{h.ip_address} ansible_user=#{h.ssh_username} ansible_ssh_private_key_file=#{h.ssh_key} ansible_ssh_extra_args="#{h.ssh_extra_args}")
          end.join("\n")
        end
      end
    end
  end
end
