module BarkingIguana
  module Compound
    module Ansible
      class Inventory
        attr_accessor :path
        private :path=

        def initialize path
          self.path = path
        end

        def hostgroups
          hg = InventoryParser.load_targets path
          hg.reject! do |k,v|
            k =~ /:vars$/
          end
          hg
        end

        def hosts
          hosts = hostgroups.values.flatten.compact.uniq { |h| h['uri'] }
          hosts.map do |data|
            name = data['name'].gsub(/ .*/, '')
            Host.new name: name, ip_address: data['uri']
          end
        end
      end
    end
  end
end
