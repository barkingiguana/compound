# CHANGELOG

Entries are in reverse chronological order.

## *0.1.3-alpha* (Current Development)

  Add release notes here, as things are added to the project.

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
