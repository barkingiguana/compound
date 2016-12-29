# CHANGELOG

Entries are in reverse chronological order.

## *0.1.6* (Current Development)

Add release notes here, as things are added to the project.

## *0.1.5* (2016-12-29)

  * Bug fix: Only generate connection inventory for those hosts in the current
    stage.

## *0.1.4* (2016-12-27)

  * Bug fix: allow connecting to VMs when we generate their IP address on
    the fly.

  * Bug fix: correctly expand the staging directory when searching for
    the stages `playbook.yml` or `inventory` file.

## *0.1.3* (2016-12-27)

  * Various bug fixes - mostly typos that would stop the full test run
    happening.

  * Add a command line tool, so we don't need the `Rakefile`. Currently this
    only handles running the entire test suite.

  * Stop requiring that the inventory files specify an IP address. If no
    IP address is provided for a VM it will be assigned an unallocated one.

  * Simplify asking Compound to define Rake tasks by allowing it to guess
    the directories involved. These can still be overridden, but they
    shouldn't normally need to be.

  * Stop supporting the concept of 'simple' tests - tests which have only
    one implicit stage. Compound feels most useful when focussing on
    lifecycle style tests which have several stages.

## *0.1.2* (2016-12-16)

  Allow a default inventory and playbook for each test, living in the test
  directory instead of in each stage. This is less likely to be useful for
  the playbook, but a default inventory will reduce duplication.

## *0.1.1* (2016-12-16)

  Symlink wrapper playbooks instead of writing temporary playbooks with
  includes.

## *0.1.0* (2016-12-11)

  Initial release.
