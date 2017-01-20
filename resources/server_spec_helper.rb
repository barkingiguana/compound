require 'serverspec'
require 'rspec/wait'

set :backend, :ssh
set :host, ENV['TARGET_HOST']
set :ssh_options, user: ENV['TARGET_SSH_USER'], keys: [ENV['TARGET_SSH_KEY']]
