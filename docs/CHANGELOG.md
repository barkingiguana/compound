# CHANGELOG

Entries are in reverse chronological order.

## *0.1.18* (Current Development)

  * ...

## *0.1.17* (2017-09-27)

  * Bug fix: I made a typo

## *0.1.16* (2017-09-27)

  * Support extra vars files per stage and per suite, in the form on an
    `extra_vars.json` in the stage directory, with a fallback to the suite
    directory.

## *0.1.15* (2017-09-25)

  * Performance improvement: don't query Vagrant for each host for status
    individually when building the connection inventory. This mostly affects
    test inventories that have large-ish collections of hosts, and saves
    approx 30s per host.

## *0.1.14* (2017-05-26)

  * Bug fix: the path to Vagrant isn't always `/usr/local/bin`. Remove the
    hard coding and rely on $PATH. [#1]

## *0.1.13* (2017-02-23)

  * Bug fix: `reject!` won't always return the `Hash`. We need to return
    that explicitly.

## *0.1.12* (2017-02-23)

  * Initial support for testing the results of the playbook run, to check for
    number of changes applied by `ansible-playbook`.

## *0.1.11* (2017-01-17)

  * Increase wait time for Ansible Playbook run to 1 hour instead of teh default
    10 minutes.

## *0.1.10* (2017-01-17)

  * Bug fix: Ignore group variables in inventories. Previously these were
    treated as hosts.

## *0.1.9* (2017-01-12)

  * Only generate per-stage per-action tasks if the ENV variable `DEBUG` is set
    (to anything that's not the empty string).

## *0.1.8* (2017-01-08)

  * Clean up the generated inventory after the test has run.

  * Add a simple example in lieu of tests.

  * Code clean-up including using `Forwardable` to avoid lots of tiny
    forwarding methods, and correctly namespacing the `ServerSpec` and
    `Vagrant` classes. Sorry for polluting your programmes!

## *0.1.7* (2017-01-06)

  * Allow setting the Vagrantfile.erb template in the root of the test suite to
    provide a default to use if there are no test specific customisations
    required.

## *0.1.6* (2017-01-05)

  * Allow setting ENV variables for the Vagrant command by adding an `env` file
    to the test suite or individual test.

  * Bug fix: set correct Ansible variable for SSH key to access VMs.

  * Allow setting verbosity of Ansible output using `ANSIBLE_VERBOSITY`. This
    will only be seen if `LOG_LEVEL` is `debug`, but it can be handy even in
    that case.

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
