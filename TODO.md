# TODO

* We can add machines to different networks because even though we require `10.8.*`, the networks created are `/24`'s. These should either be `/16` to avoid surprises, or we should make the CIDR configurable, or we should give an example showing this behaviour.
* Tests. So ironic that a testing tool has no tests. For release 1.0.0 we need tests.
* A host doesn't have a `uri`, it's got an IP address.
* We should support the ansible remote user attributes in the inventory, for each host.
