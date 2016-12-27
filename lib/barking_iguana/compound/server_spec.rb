class ServerSpec
  attr_accessor :stage

  def initialize stage
    self.stage = stage
  end

  include BarkingIguana::Logging::Helper
  include BarkingIguana::Benchmark

  def run
    logger.debug { "Host tests: #{host_tests.inspect}" }
    host_tests.each do |host_name, test_files|
      command = "bundle exec ruby -S rspec -r #{control_repo_dir}/library/spec_helper.rb #{test_files.join(' ')}"
      c = Mixlib::ShellOut.new command, live_stream: logger, cwd: control_repo_dir, env: env_for(host_name)
      benchmark command do
        c.run_command
      end
      c.error!
    end
  end

  def control_repo_dir
    stage.test.suite.control_directory
  end

  def host_for host_test
    stage.test.host_manager.find_by_name host_test['name']
  end

  def env_for host_test
    host = host_for host_test
    raise "Could not find host #{host_test} in inventory #{hosts.inspect}" unless host
    # TODO: Keep these in the host object
    {
      TARGET_HOST: host['uri'],
      TARGET_SSH_USER: 'vagrant',
      TARGET_SSH_KEY: "#{ENV['HOME']}/.vagrant.d/insecure_private_key"
    }
  end

  def root_dir
    stage.directory
  end

  def hosts
    stage.test.host_manager.all
  end

  def host_tests
    hosts.inject({}) do |a,e|
      name = e.name
      glob = "#{root_dir}/{#{name}/**/*_,}spec.rb"
      logger.debug { "Host glob for #{name.inspect} = #{glob.inspect}" }
      tests = Dir.glob glob
      logger.debug { "Host tests for #{name.inspect} = #{tests.inspect}" }
      if !tests.empty?
        if e.state != 'running'
          raise "There are tests for #{name} in #{stage.stage_directory}, but the host is #{e.state}"
        end
        a[e] = tests
      end
      a
    end
  end
end
