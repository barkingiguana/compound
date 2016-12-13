class Vagrant
  attr_accessor :manager
  private :manager=, :manager

  attr_accessor :vagrant_file_template_path
  private :vagrant_file_template_path=, :vagrant_file_template_path

  attr_accessor :root
  private :root=, :root

  attr_accessor :environment
  private :environment=, :environment

  def initialize manager, options = {}
    self.manager = manager
    self.vagrant_file_template_path = options[:vagrant_file_template_path] || File.expand_path('../../../../resources/Vagrantfile.erb', __FILE__)
    self.root = options[:root] || Dir.pwd
    self.environment = options[:environment] || {}
  end

  include BarkingIguana::Logging::Helper
  include BarkingIguana::Benchmark

  {
    up: "",
    status: "",
    halt: "-f",
    destroy: "-f"
  }.each_pair do |command, always_args|
    define_method command do |*passed_args|
      logger.debug { "COMMAND: #{command.inspect}, PASSED_ARGS: #{passed_args.inspect}, ALWAYS_ARGS: #{always_args.inspect}" }
      merged_args = ([always_args] + passed_args).flatten.join(' ').strip
      logger.debug { "MERGED ARGS: #{merged_args.inspect}" }
      command_line = "/usr/local/bin/vagrant #{command} #{merged_args}".strip
      logger.debug { "COMMAND LINE: #{command_line.inspect}" }
      c = Mixlib::ShellOut.new command_line, cwd: root, env: environment, live_stream: logger
      benchmark "running command #{command_line.inspect} in #{root.inspect} with env #{environment.inspect}" do
        c.run_command
      end
      c.error!
      c.stdout
    end
  end

  def write_file
    logger.debug { "Writing Vagrantfile to #{vagrant_file_path}" }
    File.open vagrant_file_path, 'w' do |f|
      f.puts vagrant_file_content
    end
  end
  alias_method :prepare, :write_file

  def vagrant_file_content
    ERB.new(vagrant_file_template).result binding
  end

  def vagrant_file_template
    File.read vagrant_file_template_path
  end

  def vagrant_file_path
    File.join root, 'Vagrantfile'
  end

  def refresh_status
    current_status = status.split(/\n/)
    hosts.each do |host|
      current_status.each do |line|
        if line =~ /^#{host.name}\b/
          host.state = line.sub(host.name, '').sub('(virtualbox)', '').strip
        end
      end
    end
  end

  def hosts
    manager.hosts
  end
end
