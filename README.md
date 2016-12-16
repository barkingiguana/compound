# BarkingIguana::Compound

Compound testing for Ansible atoms.

When you need to test several roles and/or playbooks together over their lifetime e.g. testing database failover and recovery.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'barking_iguana-compound'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install barking_iguana-compound

## Usage

Install it, as per above.

Normally you'll use Compond as part of a Rake task, so include it in your
`Rakefile`. Tell it to define Rake tasks for your compound tests - we assume
these live in `test/compound` - and where your playbooks live, your control
repository:

```ruby
require 'barking_iguana/compound'
ansible_control_repo = File.dirname __FILE__
BarkingIguana::Compound.new('test/compound', ansible_control_repo).define_rake_tasks
```

Now let's define a test managing hosts files. It's a trivial test, but it
suffices to demonstrate the capacilities of Compound.

### Writing a compound test

Create a directory for the test:

    $ mkdir -p test/compound/hosts_file_management

Each test will have several _stages_, which represent parts of the expected
lifecycle of your servers. For example, you set up your servers using Ansible,
to you probably have a setup stage. You may be setting up a HA cluster, so
perhaps you have a stage where the master in the cluster fails.

Each stage involves several actions. We'll cover them in detail below, but in
summary:

The `setup` action runs first. For each stage this action decides which virtual
machines should be powered on or off during the rest of the stage.

Next, the `converge` action runs the playbook for that stage, if one is provided
by you, to allow things to happen. The playbook may apply roles or kill
processes, whatever you need to simulate what's happening to your servers at
that part of the lifecycle.

Finally, the `verify` stage runs some serverspec tests which you will define
against the results of the `converge` action. This allows you to check what
happens after the tasks in the playbook have been run e.g. you may verify that a
standby server has become the master.

Each stage lives in a directory inside the test. They're executed in
alphabetical order, and you are encouraged to prefix each stage with numbers to
make it very clear which one should execute in which order.

We'll cover each of those actions in greater detail now, for the setup stage of
our hosts file example.

#### Test Stages

Start by creating the directory for that stage:

    $ mkdir -p test/compound/hosts_file_management/000-setup

##### The Setup Action

This action controls which virtual machines are available for you to work with,
by looking at an Ansible inventory file in the stage directory and starting all
the hosts it finds.

Let's create a simple inventory file with 2 hosts and 1 group.

The inventory file for each stage lives in the stage directory in a file called
`inventory`, so in our example so for that's `test/compound/hosts_file_management/000-setup/inventory`.

They're just normal Ansible inventory files, with only one restriction: the
`ansible_host` _must_ start with `10.8.`.

```
[linux]
host001 ansible_host=10.8.100.11
host002 ansible_host=10.8.100.12
```

When the setup action for a stage with this inventory is run, Compound will
launch two virtual machines for you to test with, `host001` and `host002` with
the respective IP addresses.

##### The Converge Action

Now that virtual machines are available to use, the converge action can run
the playbook for your stage against them.

Playbooks live in the stage directory, in a file called `playbook.yml`. I'm
inventive like that. For our example stage that's `test/compound/hosts_file_management/000-setup/playbook.yml`.

For our setup action we'll apply the `hosts` role to all hosts.

```
---
- hosts: all
  roles:
    - hosts
```

After a converge, Compound will attempt to verify whatever you ask it to.
Onwards, to the verify action.

##### The Verify Action

Now we run automated tests to assert that our virtual machines behave like we
think they should, after the stage playbook has been applied in the converge
action.

The verify action is based around serverspec tests, arranged around the name of
the host which they test.

For example, to test `host001` we'd create tests under a `test/compound/hosts_file_management/host001/`
directory. Each test file must be suffixed with `_spec.rb`. A simple example
would be checking that the other host of the pair is resolvable now that the
hosts role has been applied to the hosts:

```ruby
# test/compound/hosts_file_management/host001/resolving_spec.rb
describe host('host002') do
  it "is resolvable" do
    expect(subject).to be_resolvable
  end
end
```

```ruby
# test/compound/hosts_file_management/host002/resolving_spec.rb
describe host('host001') do
  it "is resolvable" do
    expect(subject).to be_resolvable
  end
end
```

Compound will take the appropriate actions to make sure your tests are run on
the correct hosts, you don't need to worry about SSH keys, passwords or ports.

### Running the tests

Since we've asked Compound to define rake tasks above, we can run those. The tasks generated are based on the directory names we use in the tests. The above test can be run like this:

    $ bundle exec rake compound:hosts_file_management

You can see a list of all tests by asking Rake to list them:

    $ bundle exec rake -T

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/barkingiguana/compound.
