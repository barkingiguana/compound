class Vagrant
  attr_accessor :vagrant_file_path
  private :vagrant_file_path=, :vagrant_file_path

  def initialize vagrant_file_path
    self.vagrant_file_path = vagrant_file_path
  end

  include BarkingIguana::Logging::Helper
  include BarkingIguana::Benchmark

  def root
    File.dirname vagrant_file_path
  end

  {
    up: "",
    status: "",
    halt: "-f",
    destroy: "-f"
  }.each_pair do |command, clargs|
    define_method command do |*args|
      command_line = "/usr/local/bin/vagrant #{command} #{clargs} #{args.join(' ')}"
      c = Mixlib::ShellOut.new command_line, cwd: root, env: env, live_stream: logger
      benchmark "running command #{command_line.inspect} in #{root.inspect} with env #{env.inspect}" do
        c.run_command
      end
      c.error!
      c.stdout
    end
  end

  def env
    {
      "HTTP_PROXY": "http://10.224.23.8:3128",
      "HTTPS_PROXY": "http://10.224.23.8:3128",
    }
  end
end
