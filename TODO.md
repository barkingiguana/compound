# TODO

* We can add machines to different networks because even though we require
  `10.8.*`, the networks created are `/24`'s. These should either be `/16` to
  avoid surprises, or we should make the CIDR configurable, or we should give an
  example showing this behaviour.

* Tests. So ironic that a testing tool has no tests. For release 1.0.0 we need tests.

* A host doesn't have a `uri`, it's got an IP address.

* We should support the ansible remote user attributes in the inventory, for each host.

* It should be possible to run these tests without a `Rakefile`, since it's
  unlikely that most Ansible control repositories will already have one of
  these. It should also be possible to run without a `Gemfile`, by relying on
  system gems, if we really want to.
