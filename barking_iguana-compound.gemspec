# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'barking_iguana/compound/version'

Gem::Specification.new do |spec|
  spec.name          = "barking_iguana-compound"
  spec.version       = BarkingIguana::Compound::VERSION
  spec.authors       = ["Craig R Webster"]
  spec.email         = ["craig@barkingiguana.com"]

  spec.summary       = %q{Compound testing of Ansible playbooks}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/barkingiguana/compound"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency 'barking_iguana-logging'
  spec.add_dependency 'barking_iguana-benchmark'
  spec.add_dependency 'mixlib-shellout'
  spec.add_dependency 'rspec-wait'
  spec.add_dependency 'ansible_spec'
  spec.add_dependency 'colorize'
  spec.add_dependency 'hostlist_expression'
  spec.add_dependency 'oj'
end
