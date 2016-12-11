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
          InventoryParser.load_targets path
        end

        def hosts
          h = hostgroups
          h.reject! { |hg| hg[0].empty? }
          hosts = h.values.flatten.uniq { |i| i['uri'] }
          hosts.each do |host|
            host['name'].gsub!(/ .*/, '')
          end
          hosts
        end
      end
    end
  end
end
