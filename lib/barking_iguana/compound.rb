require 'barking_iguana/logging'
require 'barking_iguana/benchmark'

require 'erb'
require 'forwardable'
require 'mixlib/shellout'
require 'hostlist_expression'
require 'oj'
require 'yaml'

require 'barking_iguana/compound/version'
require 'barking_iguana/compound/ansible'
require 'barking_iguana/compound/ansible/inventory'
require 'barking_iguana/compound/ansible/inventory_parser'
require 'barking_iguana/compound/ansible/inventory_writer'
require 'barking_iguana/compound/ansible/playbook'
require 'barking_iguana/compound/command_line_client'
require 'barking_iguana/compound/environment'
require 'barking_iguana/compound/host_manager'
require 'barking_iguana/compound/host'
require 'barking_iguana/compound/server_spec'
require 'barking_iguana/compound/test_stage'
require 'barking_iguana/compound/test'
require 'barking_iguana/compound/test_suite'
require 'barking_iguana/compound/vagrant'

module BarkingIguana
  module Compound
  end
end

BarkingIguana::Logging.default_level = Logger.const_get(ENV['LOG_LEVEL'].upcase) if ENV['LOG_LEVEL']
